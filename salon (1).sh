#! /bin/bash

PSQL="psql -X --username=freecodecamp --dbname=salon --no-align --tuples-only -v ON_ERROR_STOP=1"

# Escape single quotes before using input in SQL.
SQL_ESCAPE() {
  printf '%s' "$1" | sed "s/'/''/g"
}

printf '\n~~~~~ MY SALON ~~~~~\n'

while true
do
  printf '\nWelcome! Here are our services:\n'
  $PSQL -c "SELECT service_id || ') ' || name FROM services ORDER BY service_id;"

  printf '\nWhich service would you like?\n'
  read SERVICE_ID_SELECTED || exit 0

  SERVICE_NAME=""
  if [[ "$SERVICE_ID_SELECTED" =~ ^[0-9]+$ ]]
  then
    SERVICE_NAME=$($PSQL -c "SELECT name FROM services WHERE service_id::text = '$SERVICE_ID_SELECTED';")
  fi

  if [[ -n "$SERVICE_NAME" ]]
  then
    break
  fi

  printf '\nThat service does not exist. Please choose again.\n'
done

printf '\nWhat is your phone number?\n'
read CUSTOMER_PHONE || exit 0
PHONE_SQL=$(SQL_ESCAPE "$CUSTOMER_PHONE")

CUSTOMER_ID=$($PSQL -c "SELECT customer_id FROM customers WHERE phone = '$PHONE_SQL';")

if [[ -z "$CUSTOMER_ID" ]]
then
  printf '\nWhat is your name?\n'
  read CUSTOMER_NAME || exit 0
  NAME_SQL=$(SQL_ESCAPE "$CUSTOMER_NAME")

  $PSQL -c "INSERT INTO customers (phone, name) VALUES ('$PHONE_SQL', '$NAME_SQL');" > /dev/null || exit 1

  CUSTOMER_ID=$($PSQL -c "SELECT customer_id FROM customers WHERE phone = '$PHONE_SQL';")
else
  CUSTOMER_NAME=$($PSQL -c "SELECT name FROM customers WHERE customer_id = $CUSTOMER_ID;")
fi

printf '\nWhat time would you like your %s, %s?\n' "$SERVICE_NAME" "$CUSTOMER_NAME"
read SERVICE_TIME || exit 0
TIME_SQL=$(SQL_ESCAPE "$SERVICE_TIME")

$PSQL -c "INSERT INTO appointments (customer_id, service_id, time) VALUES ($CUSTOMER_ID, $SERVICE_ID_SELECTED, '$TIME_SQL');" > /dev/null || exit 1

printf '\nI have put you down for a %s at %s, %s.\n' "$SERVICE_NAME" "$SERVICE_TIME" "$CUSTOMER_NAME"
