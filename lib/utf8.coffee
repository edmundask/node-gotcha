class UTF8
   encode: (s) ->
    c = undefined
    i = -1
    l = (s = s.split("")).length
    o = String.fromCharCode

    while ++i < l
      s[i] = (if (c = s[i].charCodeAt(0)) >= 127 then o(0xc0 | (c >>> 6)) + o(0x80 | (c & 0x3f)) else s[i])
    s.join ""

  decode: (s) ->
    a = undefined
    b = undefined
    i = -1
    l = (s = s.split("")).length
    o = String.fromCharCode
    c = "charCodeAt"

    while ++i < l
      ((a = s[i][c](0)) & 0x80) and (s[i] = (if (a & 0xfc) is 0xc0 and ((b = s[i + 1][c](0)) & 0xc0) is 0x80 then o(((a & 0x03) << 6) + (b & 0x3f)) else o(128))
      s[++i] = ""
      )
    s.join ""   

module.exports = UTF8