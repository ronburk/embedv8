# Makefile - how to build decent server

# These two are overrideable by environment variable
V8?=../../../v8
V8OBJ?=$(V8)/out/x64.debug


#CPPFLAGS+=-v -g -I../v8/include -Wall -stdlib=libc++ -pthread -fsanitize=address
CPPFLAGS+=-v -g  -D_LIBCPP_ABI_VERSION=Cr -Wall  -stdlib=libc++ -pthread -fsanitize=address

EXE=hello


OBJDIR=obj
$(OBJDIR)/%.o: %.cc
	$(CXX) -g -Wall -c -o $@ $<

OBJNAMES=hello-world.o
OBJ=$(patsubst %.o,$(OBJDIR)/%.o,$(OBJNAMES))
LIBPATHS=-L$(V8OBJ)
LIBS=-lv8 -lv8_libplatform
CXX=$(V8)/third_party/llvm-build/Release+Asserts/bin/clang++

LDFLAGS=$(LIBPATHS) $(LIBS) -stdlib=libc++ -v -Wl,-rpath,../v8/out/x64.debug

CLDIR=../v8/buildtools/third_party/libc++/trunk
#all :
#	$(CXX) -v -fsanitize=address -g   test.cc -L../v8/out/debug -stdlib=libc++ 

#	$(CXX) -v -fsanitize=address -g -L$(CLDIR)/lib -stdlib=libc++  test.cc

all : $(EXE)
$(EXE) : $(OBJ)
	$(CXX)  $^ $(LDLIBS) -o $@ -pthread -fsanitize=address $(LDFLAGS)

clean	:
	-rm -f *.o ./hello

#check	: all
#	valgrind --leak-check=full --track-origins=yes --verbose --log-file=valgrind.txt ./decent
