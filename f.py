
# -*- coding: utf-8 -*-
import re
from collections import namedtuple
from UserList import UserList
# from foxycss import FoxyCss, CollectionCSS, CssSelector

import re


class CollectionCSS:
    pass


re_selector = "([a-zA-Z0-9\-\_]+)|" + \
    "\.([a-zA-Z0-9\-\_]+)|" + \
    "\#([a-zA-Z0-9\-\_]+)|\:([a-zA-Z0-9\-\_]+)"


class CssSelector:
    def __init__(self, item):
        self.parsed = []
        css = item.split(' ')
        for c in css:
            modif = []
            kws = {}
            for arg in re.findall(re_selector, c):
                if arg[0]:
                    kws["tagname"] = arg[0]
                elif arg[1]:
                    kws["cls"] = arg[1]
                elif arg[2]:
                    kws["id"] = arg[2]
                elif arg[3]:
                    modif.append(arg[3])
                self.parsed.append((kws, modif))

    def __str__(self):
        return str(self.parsed)

    def __repr__(self):
        return repr(self.parsed)


class FoxyCss:
    def __init__(self, css):
        self.tree = FoxyCss.proccess(
            FoxyCss.tree(
                [FoxyCss.parse_line(line) for line in
                    [line for line in
                        css.replace('\r', '\n').split('\n') if line.strip()
                     ]
                 ]
            )
        )

    def apply(self, fhtml):
        return FoxyCss._apply(self.tree, fhtml)

    @staticmethod
    def parse_line(line):
        stripped = line.lstrip()
        ident = (len(line) - len(stripped))  # / 4
        stripped = stripped.rstrip()
        colon = stripped.endswith(':')
        if colon:
            stripped = stripped.rstrip(':')

        '''
        parentheses = stripped.endswith(')')
        if parentheses:
            stripped = stripped.rstrip(')')
            stripped, parentheses = stripped.rsplit('(', 1)
            stripped = stripped.strip()
        '''
        parentheses = '@' in stripped
        if parentheses:
            stripped, parentheses = stripped.split('@', 1)
            stripped = stripped.strip()
            parentheses = eval('lambda t:(t%s) if t is not None else None'
                               % parentheses.replace('@', 't'))

        return ident, colon, stripped if colon else \
            CssSelector(stripped), parentheses

    @staticmethod
    def tree(parsed_css):
        t = []
        while parsed_css:
            parent = parsed_css.pop(0)
            childs = []
            while parsed_css and parent[0] != parsed_css[0][0]:
                childs.append(parsed_css.pop(0))
            t.append((parent, FoxyCss.tree(childs)))
        return t

    @staticmethod
    def proccess(t):
        f = {}
        l = []
        for parent, childs in t:
            ident, iskey, tag, attr = parent
            if iskey:
                #print ident, tag, childs
                f[tag] = FoxyCss.proccess(childs)
            else:
                if childs:
                    l.append((tag, FoxyCss.proccess(childs)))
                else:
                    l.append((tag, attr))
        return f or l or None

    @staticmethod
    def _apply(tree, fhtml):
        r = None
        if isinstance(tree, dict):
            r = {k: FoxyCss._apply(v, fhtml) for k, v in tree.iteritems()}
        elif isinstance(tree, list):
            r = []
            for item in tree:
                t = fhtml._select(item[0])
                if isinstance(item, tuple) and isinstance(item[1],
                                                         (list, dict)):
                    #codigo con hijos
                    ks = item[1].keys()
                    if ks == ['$value', '$key'] or ks == ['$key', '$value']:
                        key = item[1]['$key']
                        value = item[1]['$value']
                        fn = FoxyCss._apply
                        t = {(fn(key, it)): (fn(value, it)) for it in t}
                    else:
                        is_collection = isinstance(t, CollectionCSS)
                        t = [FoxyCss._apply(item[1], it) for it in t] if \
                            is_collection else FoxyCss._apply(item[1], t)
                elif item[1]:  # codigo tras la arroba
                        t = item[1](t)
                r.append(t)
            if len(tree) == 1:
                r = r[0]
        else:
            print tree

        return r

    def __str__(self):
        return str(self.tree)

    def __repr__(self):
        return repr(self.tree)


def foxy_css(css, fhtml):
    return FoxyCss(css).apply(fhtml)



#(tag and re.search('<([a-zA-Z]+)', tag).group(1)) or
#(closetag and re.search('</([a-zA-Z]+)', closetag).group(1) or '').lower() )

re_html = re.compile("""(</[a-zA-Z]+[^>]*>)                 #closetag
                        |(<[a-zA-Z]+(?:[^/>]|/[^>])*/>)     #singletag
                        |(<[a-zA-Z]+[^>]*>)                 #tag
                        |([^<]+)                            #notag
                        |(<![^>]*>)                         #comment
                        |(.)                                #other
                        """, re.DOTALL | re.X)


re_tag = re.compile("<([a-zA-Z]+[0-9]*)", re.DOTALL)
re_tag_id = re.compile("""id=(("[^"]*")|('[^']*')|[^\s>]+)""", re.DOTALL)
re_tag_cls = re.compile("""class=(("[^"]*")|('[^']*')|[^\s>]+)""", re.DOTALL)
re_closetag = re.compile("</([a-zA-Z]+[0-9]*)", re.DOTALL)
re_spaces = re.compile("\s+")

singles = ['meta', 'img', 'link', 'input', 'area', 'base', 'col', 'br', 'hr']
allow = ['alt', 'src', 'href', 'title']
inlineTags = ['a', 'abbr', 'acronym', 'b', 'br', 'code', 'em', 'font', 'i',
              'img', 'ins', 'kbd', 'map', 'samp', 'small', 'span', 'strong',
              'sub', 'sup', 'textarea']


def re_attr(name):
    expr = """%s=(("[^"]*")|('[^']*')|[^\s>]+)"""
    return re.compile(expr % name, re.DOTALL | re.IGNORECASE)


def get_attr(name):
    if name not in get_attr.regexps:
        get_attr.regexps[name] = re_attr(name)
    return get_attr.regexps[name]
get_attr.regexps = {}

Type_node_attrs = 'tag singletag closetag notag comment other'
TypeNode = namedtuple('TypeNode', Type_node_attrs)\
    ._make(Type_node_attrs.split(' '))
_Node = namedtuple('Node', 'type content extra')


class CollectionFoxyHtml(UserList, CollectionCSS):
    def attr(self, attr):
        return [node.attr(attr) for node in self if node]

    def search(self, *args, **kws):
        return CollectionFoxyHtml([t for node in self
                                   for t in node.search(*args, **kws)])

    def texts(self):
        return [node.texts() for node in self]

    def joinedtexts(self):
        return [node.joinedtexts() for node in self if node]

    def select(self, css):
        t = CollectionFoxyHtml([node.select(css) for node in self])
        return t
        if len(self) == 1:
            return t[0]
        else:
            return t


class Node(_Node):
    def attr(self, attr):
        tag = self.content
        value = get_attr(attr).search(tag)
        value = value and value.group(1).strip('"').strip("'")
        return value

    def istag(self):
        return self.type in (TypeNode.tag, TypeNode.singletag)

    def isclosetag(self):
        return self.type in (TypeNode.closetag, TypeNode.singletag)

    def tagname(self):
        if self.istag() or self.isclosetag():
            return self.extra[0]

    def id(self):
        if self.istag():
            return self.extra[1]

    def clean(self, translate_table={}, allow=allow):
        if self.type in ("closetag", "tag", "singletag"):
        #print self.extra[0], self.extra
            name = self.extra[0].lower()
            slash1 = "" if self.istag() else "/"
            slash2 = "/" if self.istag() and self.isclosetag() else ""
            for attr_name in allow:
                attr = self.attr(attr_name)
                if attr:
                    slash2 = " %s=\"%s\"%s" % (attr_name, attr, slash2)
            name = translate_table.get(name, name)
            content = "<%s%s%s>" % (slash1, name, slash2)
            self = type(self)(self.type, content, (name, None, []))
        return self


def _parseNode(closetag, singletag, tag, notag, comment, other):
    if tag:
        tagname = re_tag.search(tag).group(1)
        id = re_tag_id.search(tag)
        id = id and id.group(1).strip('"').strip("'")
        cls = re_tag_cls.search(tag)
        cls = cls and cls.group(1).strip('"').strip("'").split() or []
        if tagname in singles:
            return Node(TypeNode.singletag, tag, (tagname, id, cls))
        else:
            return Node(TypeNode.tag, tag, (tagname, id, cls))
    elif singletag:
        tagname = re_tag.search(singletag).group(1)
        id = re_tag_id.search(singletag)
        id = id and id.group(1).strip('"').strip("'")
        cls = re_tag_cls.search(singletag)
        cls = cls and cls.group(1).strip('"').strip("'").split() or []
        return Node(TypeNode.singletag, singletag, (tagname, id, cls))
    elif closetag:
        closetagname = re_closetag.search(closetag).group(1)
        return Node(TypeNode.closetag, closetag, (closetagname,))
    elif notag:
        return Node(TypeNode.notag, notag, None)
    elif comment:
        return Node(TypeNode.notag, comment, None)
    elif other:
        return Node(TypeNode.notag, other, None)


class FoxyHtml(list):
    def __init__(self, html=None):
        if html is None:
            list.__init__(self)
        elif isinstance(html, basestring):
            if isinstance(html, unicode):
                pass
            else:
                if 'utf-8' in html:
                    html = unicode(html, 'utf-8')
            list.__init__(
                self, [_parseNode(*node) for node in re_html.findall(html)])
        elif hasattr(html, 'read'):
            FoxyHtml.__init__(self, html.read())
        else:
            list.__init__(self, list(html))

    def _select(self, sel):
        r = self
        for kws, modif in sel.parsed:
            r = r.search(**kws)
            for m in modif:
                if m == "first":
                    r = r[0] if r else None
                elif m == "even":
                    r = CollectionFoxyHtml(r[::2])
                elif m == "odd":
                    r = CollectionFoxyHtml(r[1::2])
                elif m == "last":
                    r = r[-1] if r else None
        return r

    def select(self, item):
        sel = CssSelector(item)
        return self._select(sel)
        '''
        r = self
        css = item.split(' ')
        for c in css:
            modif = []
            kws = {}
            for arg in re.findall("([a-zA-Z0-9]+)|" +
                "\.([a-zA-Z0-9]+)|\#([a-zA-Z0-9]+)|\:([a-zA-Z0-9]+)", c):
                if arg[0]:
                    kws["tagname"] = arg[0]
                elif arg[1]:
                    kws["cls"] = arg[1]
                elif arg[2]:
                    kws["id"] = arg[2]
                elif arg[3]:
                    modif.append(arg[3])
            r = r.search(**kws)
            for m in modif:
                if m == "first":
                    r = r[0] if r else None
                elif m == "even":
                    r = CollectionFoxyHtml(r[::2])
                elif m == "odd":
                    r = CollectionFoxyHtml(r[1::2])
                elif m == "last":
                    r = r[-1] if r else None
        return r
        '''

    def clean(self, translate_table={}, allow=allow):
        return FoxyHtml(node.clean(translate_table, allow) for node in self)

    def foxycss(self, css):
        return FoxyCss(css).apply(self)

    def isearch(self, tagname=None, id=None, cls=None, fun=None, p=False):
        #p = True
        tagname = tagname and tagname.lower()
        y = 0
        r = []
        if p:
            print "***", tagname, id, cls, fun
        ctagname = None
        for node in self:  # [1:-1]:
            if p:
                print node
            if p:
                istag = node.istag()
                print "...*...", y, istag,\
                    istag and (not tagname or node.extra[0] == tagname),\
                    istag and (not id or node.extra[1] == id),\
                    istag and (not cls or cls in node.extra[2])

            # El orden de los if es importante para que devuelva el
            # primer y el ultimo nodo
            if not y and node.istag() and \
                (not tagname or node.extra[0] == tagname) and \
                (not id or node.extra[1] == id) and \
                (not cls or cls in node.extra[2]) and \
                    (not fun or fun(node)):
                # Guardamos porque pudiera ser que el parametro
                # tagname fuera None
                ctagname = node.extra[0]
                y += 1
                if p:
                    print "++level", tagname
            elif y and node.istag() and node.extra[0] == ctagname:
                y += 1
                if p:
                    print "++level"

            if y > 0:
                r.append(node)

            if p:
                print "--level?", y, node.isclosetag(), node.extra
            if y > 0 and node.isclosetag() and node.extra[0] == ctagname:
                y -= 1
                if p:
                    print "--level"

            if r and not y:
                yield FoxyHtml(r)
                r = []
                ctagname = None

    def search(self, tagname=None, id=None, cls=None, **kws):
        return CollectionFoxyHtml(self.isearch(tagname, id, cls, **kws))

    def rebuild(self):
        return "".join(node.content for node in self)

    def texts(self):
        return [node.content for node in self if node.type == TypeNode.notag]

    def joinedtexts(self):
        text = "".join(
            self.texts()).replace("\r", ' ').replace("\n", ' ').strip()
        return re_spaces.sub(' ', text)

    def __repr__(self):
        return repr(self.rebuild())

    def attr(self, name):
        return self[0].attr(name)

    def id(self):
        return self[0].id()


def main():
    import urllib2
    # from pprint import pprint
    # html = urllib2.urlopen("http://www.thetimes.co.uk")
    # parsed = FoxyHtml(html)

    html = "<div><table>Lorem ipsum dolor <tr class=\"needle\"><td>sit</tr></table></div>"
    parsed = FoxyHtml(html)


    print parsed.search(cls="needle")

    # print
    # print "Example1"
    # print "Way 1:"
    # results = parsed.search(cls="nib-inner")
    # for result in results:
    #     pprint(
    #         [result.joinedtexts() for result in result.search(tagname="li")])

    # print
    # print "Way 2:"
    # pprint(
    #     [result.joinedtexts() for result in parsed.foxycss(".nib-inner li")])

    # print
    # print "Example2"
    # pprint([dict(zip(["title", "body"], fields))
    #         for bricks in parsed.search(cls="brick-mpu")
    #         for brick in bricks.search(cls="brick-sixth")
    #         for fields in [brick.search(cls="f-hc").joinedtexts()]
    #         if all(fields)
    #         ])

    # print
    # print "Example3"
    # pprint([{
    #         'title': titles[0],
    #         'subtitile': titles[1],
    #         'body': brick.search(tagname="p").joinedtexts()
    #         }
    #         for bricks in parsed.search(cls="brick-arts")
    #         for brick in bricks.search(cls="brick-sixth")
    #         for titles in brick.search(cls="f-hc").texts()
    #         ])

    # print
    # print "Example4"
    # bricks = parsed.search(cls="brick-arts")
    # pprint(bricks.search(tagname="img").attr("src"))
    # print

    # print
    # print "Example5"
    # brick = bricks.search(cls="brick-sixth")[0]

    # print brick
    # print

    # print brick.rebuild()
    # print

    # print brick.clean().rebuild()
    # print


if __name__ == "__main__":
    main()
