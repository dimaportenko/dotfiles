local ls = require("luasnip")

ls.snippets = {
  all = {
    -- available in any filetype
    ls.parser.parse_snippet("expand", "-- this is what was expand!"
    ),
  },

  tsx = {
    -- tsx specific snippets
  }
}
