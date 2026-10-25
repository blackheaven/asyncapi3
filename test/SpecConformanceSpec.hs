-- | Repository-level conformance enforcement:
--
--  1. *Doc anchors* — every Haddock spec link in @src/**@ must reference an
--     anchor that actually exists in the vendored spec.
--  2. *Example coverage* — every yaml/json fenced block in the spec must be
--     either tester-annotated (covered by golden tests), in the manual list
--     below, or on the skip list with a reason. The skip list may only
--     contain blocks that are genuinely non-modelable (prose illustrations).
module SpecConformanceSpec (spec) where

import Data.ByteString qualified as BS
import Data.Char (isSpace)
import Data.List (isPrefixOf, isSuffixOf)
import Data.Set qualified as Set
import Data.Text (Text)
import Data.Text qualified as T
import Data.Text.Encoding qualified as TE
import System.Directory (doesDirectoryExist, listDirectory)
import System.FilePath ((</>))
import Test.Hspec
import TestSupport

spec :: Spec
spec = do
  describe "doc anchors" docAnchorSpec
  describe "example coverage" exampleCoverageSpec

-- | Collect all Haskell sources under @src/@ (project-relative paths).
haskellSources :: IO [FilePath]
haskellSources = do
  root <- projectRoot
  let go d = do
        entries <- listDirectory (root </> d)
        concat
          <$> mapM
            ( \e -> do
                let rel = d </> e
                isDir <- doesDirectoryExist (root </> rel)
                if isDir
                  then go rel
                  else pure [rel | ".hs" `isSuffixOf` e]
            )
            entries
  go "src"
  where

-- | All anchors defined in the vendored spec (@<a name="...">@).
specAnchors :: IO (Set.Set Text)
specAnchors = do
  md <- loadSpecMarkdown
  pure . Set.fromList $ concatMap anchorsInLine (T.lines md)
  where
    anchorsInLine l =
      case T.breakOn ("<a name=\"" :: Text) l of
        (_, rest)
          | T.null rest -> []
          | otherwise ->
              let afterAnchor = T.drop (T.length ("<a name=\"" :: Text)) rest
               in [T.takeWhile (/= '"') afterAnchor]

-- | All anchors referenced from Haskell sources via
-- @docs\/reference\/specification\/v3.1.0#<anchor>@.
referencedAnchors :: IO (Set.Set Text)
referencedAnchors = do
  root <- projectRoot
  sources <- haskellSources
  contents <- mapM (fmap (T.unpack . TE.decodeUtf8) . bsRead . (root </>)) sources
  pure . Set.fromList . concatMap refsIn $ contents
  where
    prefix = "docs/reference/specification/v3.1.0#"
    refsIn s = go s
      where
        go [] = []
        go cs
          | prefix `isPrefixOf` cs =
              let rest = drop (length prefix) cs
                  a = takeWhile (`notElem` ("() \t\r\n\"<" :: String)) rest
                  a' = reverse (dropWhile isSpace (reverse a))
               in (if null a' then [] else [T.pack a']) ++ go rest
          | otherwise = go (drop 1 cs)

docAnchorSpec :: Spec
docAnchorSpec =
  it "every referenced spec anchor exists in the vendored spec" $ do
    anchors <- specAnchors
    refs <- referencedAnchors
    let missing = Set.difference refs anchors
    missing `shouldBe` Set.empty

-- | Unannotated yaml/json blocks modeled by targeted tests outside the
-- golden machinery, as @(line, name, pointer)@ rows. The four Identifier
-- Object examples (lines 234, 240, 244, 250) are checked by
-- AsyncAPISpec.identifierExamples.
manualCoverage :: [(Int, Text, Text)]
manualCoverage =
  [ (234, "Identifier Object json urn", "/id"),
    (240, "Identifier Object yaml urn", "/id"),
    (244, "Identifier Object json https", "/id"),
    (250, "Identifier Object yaml https", "/id")
  ]

-- | Unannotated yaml/json blocks that cannot be modeled as data-model
-- golden tests, with reasons. Must shrink to genuinely non-modelable blocks.
skipCoverage :: [(Int, Text)]
skipCoverage =
  [ (21, "prose illustration of a channels object (redacted/commented)"),
    (38, "prose illustration of an operations object (inline-commented narrative)"),
    (50, "prose illustration of channel referencing a message (inline-commented narrative)"),
    (162, "pseudo-syntax fragment of Schema Object fields"),
    (2713, "traits merge mechanism: before-merge prose illustration"),
    (2724, "traits merge mechanism: after-merge prose illustration")
  ]

exampleCoverageSpec :: Spec
exampleCoverageSpec =
  it "partitions all yaml/json fenced blocks into annotated / manual / skip" $ do
    md <- loadSpecMarkdown
    let blocks = allFencedBlocks md
        modelable b = blockFormat b `elem` ["yaml", "json"]
        annotatedLines = map blockLine (annotatedExamples md)
        unannotated =
          [ (blockLine b, b)
          | b <- blocks,
            modelable b,
            blockLine b `notElem` annotatedLines
          ]
        manualLines = map (\(n, _, _) -> n) manualCoverage
        skipLines = map fst skipCoverage
        uncovered =
          [ (n, T.take 60 (T.unwords (T.words (blockBody b))))
          | (n, b) <- unannotated,
            n `notElem` manualLines,
            n `notElem` skipLines
          ]
    -- sanity: every annotation in the file produced exactly one block
    annotationCount <- pure (length (filter (T.isPrefixOf "<!-- asyncapi-example-tester:" . T.strip) (T.lines md)))
    length annotatedLines `shouldBe` annotationCount
    uncovered `shouldBe` []

bsRead :: FilePath -> IO BS.ByteString
bsRead = BS.readFile
