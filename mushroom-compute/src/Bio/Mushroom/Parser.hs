{-# LANGUAGE OverloadedStrings #-}
module Bio.Mushroom.Parser (parseQuery) where

import Bio.Mushroom.AST
import Data.Void
import Data.Text (Text)
import qualified Data.Text as T
import Text.Megaparsec
import Text.Megaparsec.Char
import qualified Text.Megaparsec.Char.Lexer as L

type Parser = Parsec Void Text

sc :: Parser ()
sc = L.space space1 empty empty

lexeme :: Parser a -> Parser a
lexeme = L.lexeme sc

symbol :: Text -> Parser Text
symbol = L.symbol sc

pCalToxicity :: Parser Expr
pCalToxicity = do
    _ <- symbol "calc_toxicity_variance"
    _ <- symbol "("
    speciesGroup <- lexeme (some alphaNumChar)
    _ <- symbol ")"
    return $ CalcToxicityVariance (T.pack speciesGroup)

pFilterPhenotype :: Parser Expr
pFilterPhenotype = do
    _ <- symbol "filter_phenotype"
    _ <- symbol "("
    trait <- lexeme (some alphaNumChar)
    _ <- symbol ","
    val <- lexeme (some alphaNumChar)
    _ <- symbol ")"
    return $ FilterPhenotype (T.pack trait) (T.pack val)

pExpr :: Parser Expr
pExpr = try pCalToxicity <|> pFilterPhenotype

parseQuery :: Text -> Either (ParseErrorBundle Text Void) Expr
parseQuery = parse (sc *> pExpr <* eof) ""

