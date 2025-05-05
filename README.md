# dbt_int_tests_suite

1. Clone the repository
```sh
git clone https://github.com/osmazur/dbt_int_tests_suite.git
```

2. cd into the main folder
```sh
cd dbt_int_tests_suite
```

3. Create the .env file. Choose the target database and add you creds
Those envs will be exported during the run of the run_test.sh file

```sh
# Create a .env configuration file
cat << EOF > .env
export DBT_TARGET=snowflake

export SNOWFLAKE_ACCOUNT=
export SNOWFLAKE_USER=
export DBT_ENV_SECRET_SNOWFLAKE_PASS=
export SNOWFLAKE_ROLE=
export SNOWFLAKE_DATABASE=
export SNOWFLAKE_WAREHOUSE=
export SNOWFLAKE_SCHEMA=

export EM_SNOWFLAKE_USER=
export EM_SNOWFLAKE_PASSWORD=
export EM_SNOWFLAKE_DB=
export EM_SNOWFLAKE_SCHEMA=
export EM_SNOWFLAKE_WAREHOUSE=

EOF
```

4. Make the sh file executable
```sh
chmod +x run_test.sh
```

5. Run integration test
```sh
./run_test.sh
```

In repos.yml there are packages with integrations tests. By default it runs integrations tests from the dbt-utils package. Uncomment other ones to run integration tests.
