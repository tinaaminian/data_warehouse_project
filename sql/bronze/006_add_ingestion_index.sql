create UNIQUE INDEX ux_ingestion_log_success
on bronze.ingestion_log(source_system,file_hash)
where status = 'SUCCESS'