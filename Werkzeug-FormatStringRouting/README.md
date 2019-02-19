# Werkzeug-FormatStringRoutig

This is a replacement for werkzeug.routing.Rule which uses str.format()-style
routing patterns.

Instead of:

```
@app.route('/topics/<topic>/edit/<int:n>')
```

...you can use:

```
@app.route('/topics/{topic}/edit/{id:n}')
```

## Using with Flask

Subclass Flask and in your subclass you can instruct Flask to use the
alternative Rule. Once done, you can instantiate it as normal:

```
from flask import Flask
from werkzeug_formatstringrouting import Rule


class CustomisedFlask(Flask):
    url_rule_class = Rule


# Use CustomisedFlask where you would use Flask
app = CustomisedFlask(__name__)
```

## Quirks & Limitations

- Matches without a type (eg. `{name}`) will not match anything containing
  slashes, similar to how Werkzeug matches strings.

- To match paths, use the `path` type: `{my_path:path}`.

- For more details on how the matching is handled and the types available,
  please see the documentation for the `parse` library.

- Use of the `redirect_to` parameter is not supported, because of how Werkzeug
  builds the target URL to redirect to.

## License

Issued under the same license as Werkzeug. Please see the LICENSE file for
more details.

## Author

Luke Ross <lr@lukeross.name>
