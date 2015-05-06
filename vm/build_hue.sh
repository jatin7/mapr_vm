#packer build --only=sandbox-base --var 'mapr_spark_version=' --var 'mapr_sqoop_version=' --var 'mapr_hue_version=' --var 'mapr_hbase_version=' --var 'mapr_pig_version=0.12.27259-1' --var 'mapr_oozie_version=4.0.1.201409291452-1' --var 'mapr_hcatalog_version=0' --var 'mapr_flume_version=0' --var 'mapr_hive_version=0.13.201411180959-1' --var 'mapr_mahout_version=0' --var 'mapr_drill_version=' --var 'mapr_version=4.1.0' --var 'mapr_core_repo_url=http://package.mapr.com/releases' --var 'mapr_eco_repo_url=http://package.mapr.com/releases/ecosystem-4.x' --var mapr_banner_url=http://%s:8443/ --var 'mapr_banner_name=MapR-Sandbox-For-Hadoop' --var 'hadoop_version=2.5.1' mapr-sandbox.json 

#packer build --only=sandbox --var 'mapr_spark_version=' --var 'mapr_sqoop_version=0' --var 'mapr_hue_version=3.7.0.201503251913-1' --var 'mapr_hbase_version=' --var 'mapr_pig_version=0.13.201503051749-1' --var 'mapr_oozie_version=4.0.1.201503051708-1' --var 'mapr_hcatalog_version=0' --var 'mapr_flume_version=0' --var 'mapr_hive_version=0.13.201503021511-1' --var 'mapr_mahout_version=0' --var 'mapr_drill_version=0' --var 'mapr_version=4.1.0' --var 'mapr_core_repo_url=http://package.mapr.com/releases' --var 'mapr_eco_repo_url=http://package.mapr.com/releases/ecosystem-4.x' --var mapr_banner_url=http://%s:8443/ --var 'mapr_banner_name=MapR-Sandbox-For-Hadoop' --var 'hadoop_version=2.5.1' mapr-sandbox.json 

packer build --only=sandbox-vmware --var 'mapr_spark_version=' --var 'mapr_sqoop_version=0' --var 'mapr_hue_version=3.7.0.201503251913-1' --var 'mapr_hbase_version=' --var 'mapr_pig_version=0.13.201503051749-1' --var 'mapr_oozie_version=4.0.1.201503051708-1' --var 'mapr_hcatalog_version=0' --var 'mapr_flume_version=0' --var 'mapr_hive_version=0.13.201503021511-1' --var 'mapr_mahout_version=0' --var 'mapr_drill_version=0' --var 'mapr_version=4.1.0' --var 'mapr_core_repo_url=http://package.mapr.com/releases' --var 'mapr_eco_repo_url=http://package.mapr.com/releases/ecosystem-4.x' --var mapr_banner_url=http://%s:8443/ --var 'mapr_banner_name=MapR-Sandbox-For-Hadoop' --var 'hadoop_version=2.5.1' mapr-sandbox.json 

