#!/bin/zsh

BOLD='\033[1m'
NORMAL='\033[0m'

ARG_1="$1"
ARG_2="$2"
ARG_3="$3"

MAIN_DIR="$HOME/.mgsh"
CONNECTIONS_DIR="$MAIN_DIR/connections"

# Wordings
NO_CONNECTION_FOUND="No connection found"
NO_NAMESPACE_FOUND="No namespace found"
INVALID_NAMESPACE="Invalid namespace"

show_help() {
  echo "${BOLD}$ mgsh [command] [options]${NORMAL}"
  echo ""
  echo "${BOLD}connection format:${NORMAL}"
  echo "  <namespace>/<connection-name>"
  echo "  example: dev/myapp"
  echo ""
  echo "${BOLD}possible namespaces:${NORMAL}"
  echo "  - dev"
  echo "  - beta"
  echo "  - gamma"
  echo "  - prod"
  echo "  - personal"
  echo "  - other"
  echo ""
  echo "${BOLD}Commands:${NORMAL}"
  echo "  list                                      List all available connections"
  echo "  list <namespace>                          List connections in a specific namespace (possible namespace: dev, beta, gamma, prod, personal, other)"
  echo "                                            example: mgsh list dev"
  echo "  connect                                   Connect to default MongoDB connection (mongodb://127.0.0.1:27017/?directConnection=true&serverSelectionTimeoutMS=2000)"
  echo "  connect [connection]                      Connect using the specified connection (see available connections with  mgsh list)"
  echo "                                            example: mgsh connect dev/myapp"
  echo "  get [connection]                          Copy connection string to clipboard"
  echo "  create [connection] [connection string]   Create a new connection"
  echo "  update [connection] [connection string]   Update an existing connection"
  echo "  delete [connection]                       Delete an existing connection"
  echo "  mongosh [arguments]                       Run mongosh command directly. (Run mgsh mongosh --help for more information)"
  echo ""
  echo "${BOLD}Examples:${NORMAL}"
  echo "  mgsh list"
  echo "  mgsh connect dev/myapp"
  echo "  mgsh get dev/myapp"
}

if [ $# -eq 0 ]; then
  show_help

  exit 1
fi

show_all_available_connections() {
  if [ -z "$(ls -A "$CONNECTIONS_DIR")" ]; then
    echo "$NO_CONNECTION_FOUND"
  else
    for namespace in $(ls "$CONNECTIONS_DIR"); do
      for service in $(ls "$CONNECTIONS_DIR/$namespace"); do
        echo "$namespace/$service"
      done
    done
  fi
}

show_available_connections_in_namespace() {
  if [ -z "$(ls -A "$CONNECTIONS_DIR")" ]; then
    echo "$NO_CONNECTION_FOUND"
  elif ! [[ $NAMESPACE =~ ^(dev|beta|gamma|prod|personal|other)$ ]]; then
    echo "$INVALID_NAMESPACE"
    exit 1
  elif [ ! -d "$CONNECTIONS_DIR/$NAMESPACE" ]; then
    echo "$NO_NAMESPACE_FOUND"
  else
    ls -1 "$CONNECTIONS_DIR/$NAMESPACE"
  fi
}

check_connection_format() {
  if ! [[ "$CONN" =~ ^(dev|beta|gamma|prod|personal|other)/.+$ ]]; then
    echo "Error: Invalid connection format. Expected format is <dev,beta,gamma,prod,personal,other>/<connection-name>."
    exit 1
  fi
}

check_empty_connection() {
  if [ -z "$CONN" ]; then
    echo "Error: No connection provided"
    exit 1
  fi
}

check_empty_connection_string() {
  if [ -z "$CONNECTION_STRING" ]; then
    echo "Error: No connection string provided"
    exit 1
  fi
}

case "$ARG_1" in
  "list")
    NAMESPACE="$ARG_2"

    if [ -z "$NAMESPACE" ]; then
      show_all_available_connections
    else
      show_available_connections_in_namespace
    fi

    exit 0
    ;;
  "connect")
    CONN="$ARG_2"

    if [ -z "$CONN" ]; then
      mongosh
      return
    fi

    check_connection_format

    CONNECTIONS=$(show_all_available_connections)
    if [ "$CONNECTIONS" = "$NO_CONNECTION_FOUND" ] || [ "$CONNECTIONS" = "$NO_NAMESPACE_FOUND" ]; then
      echo "$NO_CONNECTION_FOUND"
      exit 1
    fi

    MATCH=$(echo "$CONNECTIONS" | grep -x "$CONN")
    if [ -z "$MATCH" ]; then
      echo "$NO_CONNECTION_FOUND"
      exit 1
    fi

    mongosh $(cat $CONNECTIONS_DIR/$CONN)
    ;;
  "get")
    CONN="$ARG_2"

    check_empty_connection
    check_connection_format

    CONNECTIONS=$(show_all_available_connections)
    if [ "$CONNECTIONS" = "$NO_CONNECTION_FOUND" ] || [ "$CONNECTIONS" = "$NO_NAMESPACE_FOUND" ]; then
      echo "$NO_CONNECTION_FOUND"
      exit 1
    fi

    MATCH=$(echo "$CONNECTIONS" | grep -x "$CONN")
    if [ -z "$MATCH" ]; then
      echo "$NO_CONNECTION_FOUND"
      exit 1
    fi

    cat $CONNECTIONS_DIR/$CONN | pbcopy
    echo "Connection string copied to clipboard"
    exit 0
    ;;
  "create")
    CONN="$ARG_2"
    CONNECTION_STRING="$ARG_3"

    check_empty_connection
    check_connection_format
    check_empty_connection_string

    NAMESPACE=$(echo "$CONN" | cut -d '/' -f 1)

    CONNECTIONS=$(show_all_available_connections)
    MATCH=$(echo "$CONNECTIONS" | grep -x "$CONN")
    if [ -n "$MATCH" ]; then
      echo "Error: Connection already exists."
      exit 1
    fi

    if [ ! -d "$CONNECTIONS_DIR/$NAMESPACE" ]; then
      mkdir -p "$CONNECTIONS_DIR/$NAMESPACE"
    fi

    echo "$CONNECTION_STRING" > "$CONNECTIONS_DIR/$CONN"
    echo "Connection created successfully"
    exit 0
    ;;
  "update")
    CONN="$ARG_2"
    CONNECTION_STRING="$ARG_3"

    check_empty_connection
    check_connection_format
    check_empty_connection_string

    NAMESPACE=$(echo "$CONN" | cut -d '/' -f 1)

    CONNECTIONS=$(show_all_available_connections)
    MATCH=$(echo "$CONNECTIONS" | grep -x "$CONN")
    if [ -z "$MATCH" ]; then
      echo "No connection found"
      exit 1
    fi

    echo "$CONNECTION_STRING" > "$CONNECTIONS_DIR/$CONN"
    echo "Connection updated successfully"
    exit 0
    ;;
  "delete")
    CONN="$ARG_2"

    check_empty_connection
    check_connection_format

    CONNECTIONS=$(show_all_available_connections)
    if [ "$CONNECTIONS" = "No connections found" ] || [ "$CONNECTIONS" = "No namespace found" ]; then
      echo "No connection found"
      exit 1
    fi

    MATCH=$(echo "$CONNECTIONS" | grep -x "$CONN")
    if [ -z "$MATCH" ]; then
      echo "No connection found"
      exit 1
    fi

    rm -f "$CONNECTIONS_DIR/$CONN"
    echo "Connection deleted successfully"
    exit 0
    ;;
  "mongosh")
    shift
    mongosh "$@"
    exit 0
    ;;
  *)
    echo "Error: Invalid argument"
    echo ""
    show_help
    exit 1
    ;;
esac
