# Exercism Elm Test Runner

The Docker image for running Elm solutions submitted to Exercism.

## Running the tests

To run a solution's tests, open a command prompt in the root directory and run

```sh
bin/run.sh <exercise-slug> <exercise-directory> <output-directory>
```

## Running the tests using Docker

To run a solution's tests using a Docker container

```sh
# Mac / Linux
bin/run-in-docker.sh <exercise-slug> <exercise-directory> <output-directory>

# Windows
bin/run-in-docker.ps1 <exercise-slug> <exercise-directory> <output-directory>
```
