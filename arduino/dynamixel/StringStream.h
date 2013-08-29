#ifndef String_Stream_h_
#define String_Stream_h_

#include <Stream.h>

class StringStream : public Stream
{
    private:
        const char *str;
        unsigned int pos, len;

    public:
        StringStream(const char *s) : str(s), pos(0), len(strlen(s)) {}

        virtual int available();
        virtual int read();
        virtual int peek();
        virtual void flush();
        virtual size_t write(uint8_t);
};

#endif // String_Stream_h_

