package com.karchx.datapipeline.layers

import org.apache.spark.sql.{SparkSession, DataFrame, Column}
import org.apache.spark.sql.{functions => F}

object Silver {
  def sanitizeColumnName(colName: String): String = {
    var sanitized = colName.trim.toLowerCase.replaceAll("[^a-z0-9]+", "_")

    if (sanitized.matches("^[A-Za-z_]")) {
      sanitized = "_" + sanitized
    }

    sanitized
  }

  def sanitizeDataframeColumns(df: DataFrame): DataFrame = {
    var sanitizeDF = df
    df.columns.foreach { colName =>
      val sanitizedColName = sanitizeColumnName(colName)
      if (colName != sanitizedColName) {
        sanitizeDF = sanitizeDF.withColumnRenamed(colName, sanitizedColName)
      }
    }
    sanitizeDF
  }

  def mapColumnValue(
    df: DataFrame,
    columnName: String,
    mapping: Map[String, String],
    defaultValue: String
  ): DataFrame = {
    val sparkMap = F.typedLit(mapping)

    df.withColumn(
      columnName,
      F.coalesce(F.element_at(sparkMap, F.col(columnName)), F.lit(defaultValue))
    )
  }

  def transformCapShape(df: DataFrame): DataFrame = {
    val lookupShape = Map(
      "b" -> "bell",
      "c" -> "conical",
      "x" -> "convex",
      "f" -> "flat",
      "k" -> "knobbed",
      "s" -> "sunken"
    )
    
    mapColumnValue(df, "cap_shape", lookupShape, "bell")
  }

  def transformCapSurface(df: DataFrame): DataFrame = {
    val lookupSurface = Map(
      "f" -> "fibrous",
      "g" -> "grooves",
      "y" -> "scaly",
      "s" -> "smooth"
    )

    mapColumnValue(df, "cap_surface", lookupSurface, "grooves")
  }

  def transformCapColor(df: DataFrame): DataFrame = {
    val lookupColor = Map(
      "n" -> "brown",
      "b" -> "buff",
      "c" -> "cinnamon",
      "g" -> "gray",
      "r" -> "green",
      "p" -> "pink",
      "u" -> "purple",
      "e" -> "red",
      "w" -> "white",
      "y" -> "yellow",
      "o" -> "orange",
      "k" -> "black",
      "l" -> "light_brown"
    )
    
    mapColumnValue(df, "cap_color", lookupColor, "unknown")

  }

  def transformClass(df: DataFrame): DataFrame = {
    df.withColumn("class",
      F.when(F.col("class") === F.lit("e"), F.lit("edible"))
        .when(F.col("class") === F.lit("p"), F.lit("poisonous"))
        .otherwise(F.lit("unknown"))
    )
  }

  def parseBoolean(col: Column): Column = {
    val c = F.lower(F.trim(col.cast("string")))

    F.when(col.isin("t", "true", "yes", "1", "y"), true)
     .when(col.isin("f", "false", "no", "0", "n"), false)
     .otherwise(false)
  }

  def transform(df: DataFrame, columnName: String): DataFrame = {
    columnName match {
      case "cap_shape" => transformCapShape(df)
      case "cap_surface" => transformCapSurface(df)
      case "cap_color" => transformCapColor(df)
      case "class" => transformClass(df)
      case _ => df
    }
  }
  
  def load(spark: SparkSession): Unit = {

    val dfBronze = spark.read
      .format("parquet")
      .load("s3a://mushroom/bronze/")

    val df = sanitizeDataframeColumns(dfBronze)

    val columnsToTransform = Seq("class", "cap_shape", "cap_surface", "cap_color")

    val dfSilver = columnsToTransform.foldLeft(df) { (tDf, colName) =>
      tDf.transform(df => transform(df, colName))
    }

    val dfWithIngestionDate = dfSilver
      .select(
        F.col("id"),
        F.col("class"), 
        F.col("cap_shape"),
        F.col("cap_surface"),
        F.col("cap_color"),
        parseBoolean(F.col("bruises")).alias("bruises")
      )
      .withColumn("ingestion_date", F.current_timestamp().cast("date"))


    spark.sql("CREATE NAMESPACE IF NOT EXISTS lakehouse.silver")

    dfWithIngestionDate.write
      .format("iceberg")
      .mode("overwrite")
      .partitionBy("ingestion_date")
      .saveAsTable("lakehouse.silver.mushrooms")

    val dfDB = spark.sql("SELECT * FROM lakehouse.silver.mushrooms limit 100")
    dfDB.show()
  }
}
