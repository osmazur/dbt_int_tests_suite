# dbt_int_tests_suite


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

# Those envs will be exported during the run of the test.sh file

# Run integration tests
./run_test.sh

