// give the user a nice default project!

val sparkVersion = settingKey[String]("Spark version")

lazy val root = (project in file(".")).

  settings(
    inThisBuild(List(
      organization := "com.karchx",
      scalaVersion := "2.12.13"
    )),
    name := "datapipeline",
    version := "1.0.0",

    libraryDependencies ++= Seq(
      "org.apache.spark" %% "spark-streaming" % "3.5.8" % "provided",
      "org.apache.spark" %% "spark-sql" % "3.5.8" % "provided",
      "org.postgresql" % "postgresql" % "42.7.4",
      "org.apache.hadoop" % "hadoop-aws" % "3.3.4",
      "org.apache.iceberg" %% "iceberg-spark-runtime-3.5" % "1.4.3"
    ),
    assembly / assemblyOption := (assembly / assemblyOption).value.copy(includeScala = false),
    assembly / assemblyMergeStrategy := {
      case PathList("META-INF", "services", xs @ _*) => MergeStrategy.concat
      case PathList("META-INF", xs @ _*) => MergeStrategy.discard
      case "reference.conf" => MergeStrategy.concat
      case x => MergeStrategy.first
    }
  )
