# MGSH (MongoDB Shell Helper)

A simple command-line tool to manage and connect to multiple MongoDB instances easily. This tool helps you organize and quickly access different MongoDB connections across various environments (development, production, etc.).

Built on top of [mongosh](https://www.mongodb.com/docs/mongodb-shell/).

Available for MacOS (arm64) only 😅.

## Features

- Save connection strings in environment namespaces (dev, beta, gamma, prod, personal, other) that mongosh cannot do natively.
- Quick connection using saved configurations
- Create, update, and delete connection configurations
- Also works with mongosh command directly (e.g. `mgsh connect dev/myapp` is the same as `mongosh mongodb://xxxxx1`)

## Installation

1. Clone this repository:
```bash
git clone https://github.com/Warathep187/mgsh
cd mgsh
```

2. Make the script executable and run the installation script:
```bash
chmod +x install.sh
./install.sh
```

3. Verify the installation:
```bash
mgsh # should show the help menu
```
if mgsh is not found, you might need to restart your terminal or run `source ~/.zshrc` to reload the shell.

## Example Usage

```bash
# Show help
mgsh

# List all available connections
mgsh list

# List connections in a specific namespace (possible namespace: dev, beta, gamma, prod, personal, other)
mgsh list dev

# Connect to default MongoDB connection (mongodb://127.0.0.1:27017/?directConnection=true&serverSelectionTimeoutMS=2000)
mgsh connect

# Connect to MongoDB using a saved connection
mgsh connect dev/myapp

# Get and copy a connection string to clipboard
mgsh get dev/myapp

# Create a new connection
mgsh create dev/myapp mongodb://xxxxx1

# Update an existing connection
mgsh update dev/myapp mongodb://xxxxx2

# Delete a connection
mgsh delete dev/myapp
```

### Connection Format

Connections must follow the format: `<namespace>/<connection-name>`

Possible namespaces:
- dev
- beta
- gamma
- prod
- personal
- other

Example: `dev/myapp` or `prod/database1`

## Development

The project structure consists of the following files:
- `main.sh`: Main script file
- `run_tests.sh`: For running tests
- `tests/`: Contains test files
- `install.sh`: Installation script

To run in development mode:

1. Clone the repository

2. Make sure all files have executable permissions:
```bash
chmod +x *.sh
```

3. Run the script directly:
```bash
./main.sh [command] [options]
```

4. Run the tests:
```bash
./run_tests.sh
```

## Storage

Saved connection strings are stored in `~/.mgsh/connections/` directory, organized by namespace.

## Uninstallation

```bash
chmod +x uninstall.sh

# uninstall mgsh only
./uninstall.sh

# uninstall mgsh and dependencies (mongosh)
./uninstall.sh --deps
```

## Requirements

- Zsh shell
- mongosh (2.x)
