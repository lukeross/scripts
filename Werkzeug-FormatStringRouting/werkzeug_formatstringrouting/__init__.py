import re
from parse import compile, parse
from werkzeug import routing
from werkzeug.urls import url_encode, url_quote


def _path(text):
    return text


_path.pattern = routing.PathConverter.regex


class Rule(routing.Rule):
    def compile(self):
        rule = self.rule if self.is_leaf else self.rule.rstrip('/')
        self._regex = compile(rule, {
            'path': _path,
        })

        self.arguments.update(self._regex._named_fields)

        weight_map = {'path': 200, 'd': 50, 'n': 50}
        self._argument_weights = [
            weight_map.get(t, 100)
            for t in self._regex._name_types.values()
        ]

        self._static_weights = []
        self._trace = []
        for idx, part in enumerate(self.rule.split('/')):
            if not part:
                continue
            self._trace.append(('{' in part, part))
            if '{' not in part:
                self._static_weights.append((idx, -len(part)))

    def match(self, path, method=None):
        domain_value, local_path = path.split('|', 2)

        if not self.is_leaf:
            local_path = local_path.rstrip('/')

        assert self.map is not None, 'rule not bound'

        if self.map.host_matching:
            domain_rule = self.host or ''
        else:
            domain_rule = self.subdomain or ''

        result = self._regex.parse(local_path)
        if not result:
            return
        domain_result = parse(domain_rule, domain_value)
        if not domain_result:
            return

        # Ensure any no-type fields are valid
        for field_name, field_type in self._regex._name_types.items():
            if field_type:
                continue
            if not re.fullmatch(
                    routing.BaseConverter.regex, result.named[field_name]):
                return

        ret = dict()
        ret.update(domain_result.named)
        ret.update(result.named)

        if self.defaults:
            result.update(self.defaults)

        if self.strict_slashes and not self.is_leaf and not path.endswith('/'):
            raise routing.RequestSlash()

        if self.alias and self.map.redirect_defaults:
            raise routing.RequestAliasRedirect(ret)

        return ret

    def build(self, values, append_unknown=True):
        all_values = {}
        if self.defaults:
            all_values.update(self.defaults)
        all_values.update(values)

        if self.map.host_matching:
            domain_rule = self.host or ''
        else:
            domain_rule = self.subdomain or ''
        domain_rule_parsed = compile(domain_rule)

        try:
            formatted_url = self.rule.format(**{
                k: url_quote(v) for k, v in values.items()
                if k in self._regex._named_fields
            })
            formatted_domain = domain_rule.format(**{
                k: url_quote(v) for k, v in values.items()
                if k in domain_rule_parsed._named_fields
            })
        except (KeyError, ValueError):
            return None

        if append_unknown:
            leftovers = {
                k: v for k, v in values.items()
                if k not in self._regex._named_fields
                and k not in domain_rule_parsed._named_fields
            }
            if leftovers:
                formatted_url += u'?' + url_encode(
                    leftovers, charset=self.map.charset,
                    sort=self.map.sort_parameters,
                    key=self.map.sort_key)

        return formatted_domain, formatted_url
