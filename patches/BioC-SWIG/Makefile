ifndef $(SWIG)
        $(eval SWIG := $(shell which swig))
endif

$(eval SWIGVERSION := $(shell SWIG="$(SWIG)"; $$SWIG -version | grep Version | awk '{gsub(/\./," ",$$3); print $$3 }' | awk '{print $$1}'))


LIBS= -L/usr/lib64 -lxml2 -lz -lstdc++ -lm -lgcc_s -lc

DEBUG= -g

PERLPATH = $(shell perl -e 'use Config; print $$Config{archlib};')
XMLOPT = $(shell xml2-config --cflags)
CPPFLAGS= $(DEBUG) $(XMLOPT) -fPIC -I$(PERLPATH)/CORE -I.

all: BioC_full.so 

BioC_full_wrap.cpp: BioC_full.i
	$(SWIG) -w315  -perl -c++ -o BioC_full_wrap.cpp BioC_full.i

BioC_full.so: BioC_full_wrap.o BioC.o BioC_util.o BioC_libxml.o
	$(CXX) -shared -o $@ $? $(LIBS)

%.o: %.cpp
	$(CXX) -c $(CPPFLAGS) $< -o $@ 

clean: 
	rm -f BioC_full.so *.o *.pm BioC_full_wrap.cpp 
