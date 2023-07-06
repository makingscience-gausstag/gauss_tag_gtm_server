# Gauss Tag S2S Template

This template aims to replace/replicate the Gauss Tag which normally is embedded on the webpage.

## Template Setup
For the full step by step instructions on setting up the server-side tagging please follow the [Google's official guide](https://developers.google.com/tag-platform/learn/sst-fundamentals).

## Demo Website Setup

1. Create the virtual environment
    ```bash
    virtualenv .venv
    ```

1. Install dependencies
    ```bash
    pip install -r requirements.txt
    ```

1. Fill in the environment variables
    The environment variables can be created in the shell
    ```bash
    export GTM_WEB_CONTAINER_ID=GTM-XXXXXX
    ```
    or listed in an `.env` file.
    The mandatory variables are: `GTM_WEB_CONTAINER_ID` and `SECRET_KEY`. The first one is the id of the GTM web container configured in the part above, the second is a random string used by [Flask](https://explore-flask.readthedocs.io/en/latest/configuration.html).

1. Run the server
    ```bash
    python main.py
    ```