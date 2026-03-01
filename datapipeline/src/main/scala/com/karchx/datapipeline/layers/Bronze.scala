package com.karchx.datapipeline.layers

import org.apache.spark.sql.SparkSession
import org.apache.spark.sql.{functions => F}

object Bronze {

  def load(spark: SparkSession): Unit = {
    val dbConnection = (spark.read
      .format("jdbc")
      .option("url", "jdbc:postgresql://postgres:5432/mushroom")
      .option("user", "admin")
      .option("password", "password")
      .option("driver", "org.postgresql.Driver")
    )

    val df = dbConnection
      .option("dbtable", "mushroom")
      .load()

    val dfWithIngestionDate = df.withColumn("ingestion_date", F.current_timestamp().cast("date"))

    dfWithIngestionDate.write
      .format("parquet")
      .mode("overwrite")
      .partitionBy("ingestion_date")
      .save("s3a://mushroom/datacatalog/bronze/")
  }
}

