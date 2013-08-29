#include "StringStream.h"

int StringStream::available()
{
    return pos < len;
}

int StringStream::read()
{
    return str[pos++];
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

