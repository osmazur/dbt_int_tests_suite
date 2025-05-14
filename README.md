# dbt_int_tests_suite


1. Copy .env_example inside dbt_gitlab folder file and rename it to .env file.

2. Set up a connection
	i. Snowflake - replace Snowflake credentials in .env file from test to your credentials.
	ii. Embucket - launch Embucket locally, make sure connection parameters match Embucket launch parameters (if 	  you have default settings, you don't need to change anything).
	iii. Set the target database DBT_TARGET env (embucket or snowflake) by default it will be embucket

3. Make the sh file executable
```sh
chmod +x run_test.sh
```

5. Run integration test
```sh
./run_test.sh
```

In repos.yml there are packages with integrations tests. By default it runs integrations tests from the dbt-snowplow-web package.