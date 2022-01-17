import json
from flask import make_response


def hello_world(request):
    """
    hello_world
    ===========

    This is a very basic hello world Google Cloud Functions Function. It does
    just one thing: on a GET request it returns a json with the message "Hello
    World!"

    """
    if request.method == 'GET':
        return make_response(json.dumps({
            'result': 'success',
            'message': 'Hello World!'
        }))
    return make_response(json.dumps({
        'result': 'error',
        'description': 'This was a bad request and you should have not endet up here!'
    }), 400)