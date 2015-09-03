# Project Sidewalk - Instructions
This repository contains onboarding instructions for start contributing to
projects under Project Sidewalk. For example, it contains instructions on
how to install softwares and libraries that the multiple projects rely on
(e.g., PostgreSQL, PostGIS).

## Development Environment

### IDE
Effectively using an IDE for development is an important skill that you need.
When you are working on the projects, I highly recommend using IDE over using
text editors. My favorite IDEs are those offered by [JetBrains](https://www.jetbrains.com/).
They are good and they are cross-platform.
They also offer [student license](https://www.jetbrains.com/student/).

* [IntelliJ](https://www.jetbrains.com/idea/) : For the project that use Scala,
I recommend using IntelliJ with Scala plug-in.
* [PyCharm](https://www.jetbrains.com/pycharm/) : Python IDE.

### PostgreSQL, PostGIS, and pgRouting
We use PostgreSQL for persistent data storage of user data and GIS data. We choose
PostgreSQL over MySQL primarily because of its geographical data support. To install,
follow the instructions on the following pages.

* Windows:
  * [PostGIS](http://postgis.net/windows_downloads) : PostGIS's official web page. Follow the instruction to install PostgreSQL as well as PostGIS (> 2.0.0).
* OS X:
  * [Kyng Chaos](http://www.kyngchaos.com/software/postgres) : Kyng Chao offers a PostgreSQL 9.4 binary for OS X that include PostgreSQL, PostGIS, and pgRouting. This would be the easiest way to go for the OS X user. Once installed, start the database with the following command. `/usr/local/pgsql/bin/initdb -D /usr/local/pgsql/data/`. To start the postgres, run `/usr/local/pgsql/bin/postgres -D /usr/local/pgsql/data/`

## Utilities
This section introduces various tools that may become handy while working on
the projects.

### PostgreSQL Clients
It's probably not a good idea to interact with database using command line tool.
The following PostgreSQL clients provides GUI to view and manipulate the database.
* [Postico](https://eggerapps.at/postico/): A free PostgreSQL UI. I would use this if I'm on OS X machine.

### GIS Data Viewer
When you are working with GIS dataset, you have to visualize it at many stages of your research & development cycle (e.g., debugging, analysis). Following tools are what I have found handy
while working with GIS dataset.
* [QGIS](http://www.qgis.org/en/site/) : A comprehensive open source GIS tool. I recommend to install [OpenLayers plug-in](https://plugins.qgis.org/plugins/openlayers_plugin/) and [Quick OSM](https://plugins.qgis.org/plugins/QuickOSM/).
* [geojson.io](http://workshops.boundlessgeo.com/postgis-intro/) : A browser based geojson data viewer.

### GSI Data Manipulation
* [ogr2ogr](http://www.gdal.org/ogr2ogr.html) : ogr2ogr allows you to convert different file formats
* [osm2pgrouting](http://pgrouting.org/docs/tools/osm2pgrouting.html) : The application allows you to convert data from the OSM format into the pgRouting format and populate a database. If you are on OS X, you can install it via homebrew (`brew install osm2pgrouting`).
* [pgShapeloader](http://suite.opengeo.org/4.1/dataadmin/pgGettingStarted/pgshapeloader.html): The tool allows you to load a shapefile into PostgreSQL.

## Dataset
GIS dataset.
### Washington DC
1. Download OSM file using wget: http://workshop.pgrouting.org/chapters/installation.html (Use the following bounding box parameter for downloading the Washington DC dataset: -76.9,39.0,-77.1,38.8)
Or simply download the data from http://download.bbbike.org/osm/bbbike/WashingtonDC/
2. Follow the steps to import the OSM data into the PostGIS-enabled database (or use a python script with Imposm ) http://workshop.pgrouting.org/chapters/osm2pgrouting.html

## Tips and Tutorials
Tips and tutorials.

### Debugging Play applications with IntelliJ
This is based on [this stackoverflow post](http://stackoverflow.com/questions/19473941/how-to-debug-play-application-using-activator).
1. In a terminal, go to the root directory of your Play project. Then run: `activator -jvm-debug 9999`
2. Start the play application by entering `run` in the activator console.
3. Set up IntelliJ's debug setting. Go to Run > Edit Configureations...
4. Add a new configuration; click "+" and select "Remote".
5. Choose Transport: Socket, Debugger mode: Attach, Host: localhost, Port: 9999, and select the appropriate module's classpath. Click "Ok."
6. Run a debugger and set break points. Then you should be good to go!

### PostGIS and pgRouting
* FOSS4G routing with pgRouting: http://workshop.pgrouting.org/index.html
* [Introduction to PostGIS](http://workshops.boundlessgeo.com/postgis-intro/) : A comprehensive tutorial for using PostGIS.

### Git and GitHub
As you can see, we use Git and GitHub for version controll and collaboration.
See below for the list of concepts you should know:

* Branching:
  1. Create a branch to work on your task. You can create a branch by "git checkout -b <branch-name>"
  2. Make changes to the code in your branch
  3. Once you are done with editing the code, issue a "pull request"
  4. Wait for a code to be reviewed. (You can work on other stuff by branching )
  5. Merge the code once reviewed. If there are conflicts, resolve it. (http://stackoverflow.com/questions/161813/fix-merge-conflicts-in-git)
* Pull Request:
  * [Using pull requests](https://help.github.com/articles/using-pull-requests/)
* For more information, see:
  * [GitHub Training & Guides](https://www.youtube.com/watch?v=U8GBXvdmHT4): A YouTube channel for learning Git and GitHub.
  * [Git tutorial by RyPress](http://rypress.com/tutorials/git/index) : This is a short and concise tutorial of GIT. I find it more approachable than the official Git documentation.
  * [Pro Git](http://git-scm.com/doc) : The official git documentation.
