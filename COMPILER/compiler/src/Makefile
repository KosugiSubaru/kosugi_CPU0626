CC = gcc
CFLAGS = -Wall -Wextra -std=c11 -g
TARGET = compiler
SRCS = main.c tokenize.c some_fn.c parse.c codegen_sm.c
OBJS = $(SRCS:.c=.o)
HEADERS = header.h

.PHONY: all clean test

all: $(TARGET)

$(TARGET): $(OBJS)
	$(CC) $(CFLAGS) -o $@ $^

%.o: %.c $(HEADERS)
	$(CC) $(CFLAGS) -c $<

clean:
	rm -f $(TARGET) $(OBJS)

test: $(TARGET)
	../../test.sh
