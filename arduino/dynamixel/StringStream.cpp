#include "StringStream.h"

StringStream::StringStream(const char *s)
    : str(s), pos(0), len(strlen(s))
{
    setTimeout(1);
}

int StringStream::available()
{
    return pos < len;
}

int StringStream::read()
{
    if (pos < len)
      return str[pos++];
    else
      return -1;
}

int StringStream::peek()
{
    return str[pos];
}

void StringStream::flush()
{
}

size_t StringStream::write(uint8_t)
{
}

