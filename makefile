CC 		= 	/usr/bin/gcc
CC2		= 	/usr/bin/gcc
DATASOURCE      =       DBTESTDB
DB2INSTANCEPATH =       /home/$(DB2INSTANCE)
DBPATH		=	$(HOME)/db/data/$(DATASOURCE)
DBLOGPATH	=	$(HOME)/db/log/$(DATASOURCE)
DBARCHIVELOG	=	$(HOME)/db/archivelog/$(DATASOURCE)
CFLAGS 		= 	-g -w 
LIBDIR 		= 	-L$(DB2INSTANCEPATH)/sqllib/lib -ldb2
INCLUDE 	= 	-I$(DB2INSTANCEPATH)/sqllib/include
OBJ		=	db2snap.o

.SUFFIXES:  $(.SUFFIXES) .o .c .sqc
%.o:	%.c
	$(CC) $(CFLAGS) $(INCLUDE) -c $<
%.c:	%.sqc
	db2 connect to $(DATASOURCE)
	db2 prep $< bindfile
	db2 bind $*.bnd
	cp $@ $@.tmp


all : db2snap db2daemon
db2snap:	db2snap.o
	$(CC2) $(CFLAGS) $(LIBDIR) -o db2snap $< 
db2daemon:	db2daemon.o
	$(CC2) $(CFLAGS) $(LIBDIR) -o db2daemon $< 

createdb:
		rm -rf $(DBPATH)
		mkdir -p $(DBPATH)
		db2 create database $(DATASOURCE) on $(DBPATH)
		rm -rf $(DBLOGPATH)
		mkdir -p $(DBLOGPATH)
		db2 update database configuration for $(DATASOURCE) using NEWLOGPATH $(DBLOGPATH)
		rm -rf $(DBARCHIVELOG)
		mkdir -p $(DBARCHIVELOG)
		db2 update database configuration for $(DATASOURCE) using LOGARCHMETH1 'DISK:$(DBARCHIVELOG)'
		rm -rf $(HOME)/backup/$(DATASOURCE)
		mkdir -p $(HOME)/backup/$(DATASOURCE)
		db2 backup database DBTESTDB to $(HOME)/backup/$(DATASOURCE)
		db2 backup database $(DATASOURCE) online to $(HOME)/backup/$(DATASOURCE) compress include logs
savelog:
		mkdir -p ./log/sav
		cp -R $(DBLOGPATH) ./log/sav
dropdb:
		db2 drop database $(DATASOURCE)
createtable:
		db2 connect to $(DATASOURCE) 
		db2 "create table db2admin.T000001 (\
			id integer not null generated always as identity (start with 1 increment by 1),\
			pid integer not null,\
			date date not null default current date,\
			time time not null default current time,\
			object varchar(255) ,\
			primary key (pid,date,time))"
		db2 "create alias TEST.REPTEST for  db2admin.T000001"
		db2 "create table db2admin.T000002 (\
			ind integer not null generated always as identity (start with 1 increment by 1),\
			object varchar(255) ,\
			primary key (ind))"
		db2 "create alias TEST.ASTRO for  db2admin.T000001"
		db2 terminate
getenvironment:
		db2level
		cat /etc/system-release
getdbpath:
		db2 connect to $(DATASOURCE) 
		db2 "SELECT * FROM SYSIBMADM.DBPATHS"
		export LOGPATH=`db2 -x "select substr(type,1,30),substr(path,1,70) from SYSIBMADM.DBPATHS"|grep LOGPATH|awk '{print $2}'`
		echo "hallo" $(LOGPATH)
		db2 terminate
snap:
		rm -rf .sav/*
		rm -f pathout2 pathout snap.bash resnap.bash a.test
		db2 connect to $(DATASOURCE) 
		db2 -z pathout -x "select * from SYSIBMADM.DBPATHS"
		grep -v MEMBER pathout > pathout2
		grep -v LOGPATH pathout2 > pathout3
		awk '{print "mkdir -p ./sav/"$$2";cp -R",$$3"* ./sav/"$$2}' pathout3 > snap.bash
		awk '{print "mkdir -p",$$3";cp -R ./sav/"$$2"/*",$$3}' pathout3 > resnap.bash
		db2 set write suspend for database exclude logs
		db2 terminate
		chmod a+rx snap.bash resnap.bash
		bash ./snap.bash
		mkdir -p ./log/snap
		cp -R $(DBLOGPATH)/* ./log/snap
#		db2 set write resume for database
resnap:
		bash ./resnap.bash
DBLOGPATH       =       $(HOME)/db/log/$(DATASOURCE)
DBARCHIVELOG    =       $(HOME)/db/archivelog/$(DATASOURCE)

postsnap:
		db2 catalog database $(DATASOURCE) on $(DBPATH)
		cp $(DBARCHIVELOG)/db2admin/DBTESTDB/NODE0000/LOGSTREAM0000/C0000000/* $(DBLOGPATH)/NODE0000/LOGSTREAM0000
		cp -R ./log/sav/$(DATASOURCE)/* $(DBLOGPATH)
		db2 restart database dbtestdb write resume
#		db2inidb $(DATASOURCE) as snapshot
rebuilddb:	savelog dropdb resnap postsnap

droptable:
		db2 connect to $(DATASOURCE) 
		db2 "drop table db2admin.astro"
		db2 terminate
filltable1:
		db2 connect to $(DATASOURCE) 
		db2 "insert into db2admin.astro (object) values ('Mond')"
		db2 "insert into db2admin.astro (object) values ('Merkur')"
		db2 "insert into db2admin.astro (object) values ('Venus')"
		db2 "insert into db2admin.astro (object) values ('Erde')"
		db2 "insert into db2admin.astro (object) values ('Mars')"
		db2 "insert into db2admin.astro (object) values ('Jupiter')"
		db2 "insert into db2admin.astro (object) values ('Saturn')"
		db2 "insert into db2admin.astro (object) values ('Uranus')"
		db2 "insert into db2admin.astro (object) values ('Neptun')"
		db2 "insert into db2admin.astro (object) values ('Pluto')"
		db2 "insert into db2admin.astro (object) values ('Europa')"
		db2 "insert into db2admin.astro (object) values ('Afrika')"
		db2 "insert into db2admin.astro (object) values ('Mond')"
		db2 "commit"
		db2 "select * from db2admin.astro"
		db2 terminate
reorgrunstat:
		db2 connect to $(DATASOURCE) 
		db2 "reorg table db2admin.astro"
		db2 "runstats on table db2admin.astro"
		db2 terminate

filltable2:
		db2 connect to $(DATASOURCE) 
		db2 "insert into db2admin.astro (object) values ('Deneb')"
		db2 "insert into db2admin.astro (object) values ('Rigel')"
		db2 "insert into db2admin.astro (object) values ('Betelgeuse')"
		db2 "insert into db2admin.astro (object) values ('Beta Crucis')"
		db2 "insert into db2admin.astro (object) values ('Antares')"
		db2 "insert into db2admin.astro (object) values ('Beta Centauri')"
		db2 "insert into db2admin.astro (object) values ('Alpha Crucis')"
		db2 "insert into db2admin.astro (object) values ('Spica')"
		db2 "insert into db2admin.astro (object) values ('Canopus')"
		db2 "insert into db2admin.astro (object) values ('Achenar')"
		db2 "insert into db2admin.astro (object) values ('Capella')"
		db2 "insert into db2admin.astro (object) values ('Arcturus')"
		db2 "insert into db2admin.astro (object) values ('Aldebaran')"
		db2 "insert into db2admin.astro (object) values ('Vega')"
		db2 "insert into db2admin.astro (object) values ('Pollux')"
		db2 "insert into db2admin.astro (object) values ('Sirius')"
		db2 "insert into db2admin.astro (object) values ('Formalhaut')"
		db2 "insert into db2admin.astro (object) values ('Altair')"
		db2 "insert into db2admin.astro (object) values ('Procyon')"
		db2 "insert into db2admin.astro (object) values ('Alpha Centauri')"
		db2 "insert into db2admin.astro (object) values ('Sirius')"
		db2 "insert into db2admin.astro (object) values ('Procyon')"
		db2 "insert into db2admin.astro (object) values ('Alpha Centauri')"
		db2 "insert into db2admin.astro (object) values ('Epsilon Eridani')"
		db2 "insert into db2admin.astro (object) values ('Epsilon Indi')"
		db2 "insert into db2admin.astro (object) values ('61 Cygni')"
		db2 "insert into db2admin.astro (object) values ('Lalande 21135')"
		db2 "insert into db2admin.astro (object) values ('Sigma 2398')"
		db2 "insert into db2admin.astro (object) values ('Bernards Star')"
		db2 "insert into db2admin.astro (object) values ('Ross 154')"
		db2 "insert into db2admin.astro (object) values ('Ross 128')"
		db2 "insert into db2admin.astro (object) values ('Ross 248')"
		db2 "insert into db2admin.astro (object) values ('Luyten 789-6')"
		db2 "insert into db2admin.astro (object) values ('Luyten 726-8')"
		db2 "insert into db2admin.astro (object) values ('Wolf 359')"
		db2 "select * from db2admin.astro with UR"
		db2 -x "select * from db2admin.astro"
		db2 set write resume for database
		db2 commit
		db2 terminate
emptytable:
		db2 connect to $(DATASOURCE) 
		db2 "delete from db2admin.astro"
		db2 terminate
initdb:		dropdb createdb createtable filltable1

clean:
	rm -f *.c.c *.i *.o *.bnd *.tmp $(OBJ) db2snap.c db2snap db2daemon db2daemon.c
	rm -rf ./sav ./log
	rm -f pathout2 pathout snap.bash resnap.bash a.test

