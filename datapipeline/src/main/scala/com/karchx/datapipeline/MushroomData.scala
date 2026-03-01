package com.karchx.datapipeline

import org.apache.spark.{SparkConf, SparkContext}
import org.apache.spark.sql.{DataFrame, DataFrameReader, SparkSession}
import com.karchx.datapipeline.layers.{Bronze, Silver}

object MushroomData extends App {
  val sparkSession: SparkSession = SparkSession
    .builder()
    .appName("MushroomDataPipeline")
    .config("spark.sql.extensions", "org.apache.iceberg.spark.extensions.IcebergSparkSessionExtensions")
    .config("spark.sql.catalog.lakehouse", "org.apache.iceberg.spark.SparkCatalog")
    .config("spark.sql.catalog.lakehouse.type", "hadoop")
    .config("spark.sql.catalog.lakehouse.warehouse", "s3a://mushroom/datacatalog/")

    .config("spark.hadoop.fs.s3a.endpoint", "http://rustfs:9000")
    .config("spark.hadoop.fs.s3a.access.key", "IkcGaFDhv4COos87y1T2")
    .config("spark.hadoop.fs.s3a.secret.key", "lG2MmZksuCDATXWeYE5PhdV1tSoBb37wnOf6rK9U")
    .config("spark.hadoop.fs.s3a.path.style.access", "true")
    .config("spark.hadoop.fs.s3a.impl", "org.apache.hadoop.fs.s3a.S3AFileSystem")
    .getOrCreate()
  Runner.run(sparkSession)
}

object Runner {
  def run(session: SparkSession): Unit = {
    Bronze.load(session)
    Silver.load(session)
  }
}
