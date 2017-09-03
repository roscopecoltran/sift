import uuid
from importlib import reload

from sanic.config import LOGGING
from sanic.response import text
from sanic import Sanic
from io import StringIO
import logging

logging_format = '''module: %(module)s; \
function: %(funcName)s(); \
message: %(message)s'''


def reset_logging():
    logging.shutdown()
    reload(logging)


def test_log():
    log_stream = StringIO()
    for handler in logging.root.handlers[:]:
        logging.root.removeHandler(handler)
    logging.basicConfig(
        format=logging_format,
        level=logging.DEBUG,
        stream=log_stream
    )
    log = logging.getLogger()
    app = Sanic('test_logging')
    rand_string = str(uuid.uuid4())

    @app.route('/')
    def handler(request):
        log.info(rand_string)
        return text('hello')

    request, response = app.test_client.get('/')
    log_text = log_stream.getvalue()
    assert rand_string in log_text


def test_default_log_fmt():

    reset_logging()
    Sanic()
    for fmt in [h.formatter for h in logging.getLogger('sanic').handlers]:
        assert fmt._fmt == LOGGING['formatters']['simple']['format']

    reset_logging()
    Sanic(log_config=None)
    for fmt in [h.formatter for h in logging.getLogger('sanic').handlers]:
        assert fmt._fmt == "%(asctime)s: %(levelname)s: %(message)s"


if __name__ == "__main__":
    test_log()
