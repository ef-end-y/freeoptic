# FreeOptic - IDE for creating fiber-optic schemes

Online demo https://all-optic.com/

## Installation

```
docker compose build
docker compose up
```

Create a superuser with name=admin and password=12345:
```
docker exec -it freeoptic perl install.pl -p admin=12345
```

### Comments

You can change some settings in docker-compose.yml. Db directory on your host machine is freeoptic/data/mysql:

```
    volumes:
      - ./data/mysql:/var/lib/mysql
```

Www port on your host machine is 8080:

```
    ports:
      - "8080:80"
```

## Work
Open in browser
```
http://127.0.0.1:8080/cgi-bin/stat.pl
```

- Double-click or right-click in an empty space to display scheme elements creation menu

<img src="htdocs/doc/item_creation_menu.png" style="width: 353px; margin-left: 5%;">

- Unconnected fibers are not displayed. To display them, switch into "link creation mode".
In this mode you can draw connections between fiber edges of cable and connectors. You can also link connectors with a patch cord

<img src="htdocs/doc/link_creation_mode.png" style="width: 309px; margin-left: 5%;">


- You can change fiber ordering or connector ordering. Drag the fiber edge or the connector

<img src="htdocs/doc/fiber_order.png" style="width: 495px; margin-left: 5%;">


- You can change cable position or cable path. Right click on a cable and select "create a joint". Left click on a joint and move it.

<img src="htdocs/doc/cable_position.png" style="width: 311px; margin-left: 5%;">
<img src="htdocs/doc/cable_path.png" style="width: 350px; margin-left: 5%;">

- You can group items in a container. First create a container. Then use drag and drop

<img src="htdocs/doc/container.png" style="width: 200px; margin-left: 5%;">

- You can set names and descriptions for all objects. For example splitter 10%-90% 

<img src="htdocs/doc/connector_descriptions.jpg" style="width: 400px; margin-left: 5%;">

- Undo/redo buttons (<img src="htdocs/doc/undo_redo.png" style="vertical-align: middle;">) and history button (<img src="htdocs/doc/history.png" style="vertical-align: middle;">) allow you to rewind actions forward and backward

<img src="htdocs/doc/history_window.png" style="width: 391px; margin-left: 5%;">

- A scheme may contain thousands of objects. At a large scale they will be shown schematically. When zoomed in, the objects will be shown in full

<img src="htdocs/doc/zoom.png" style="width: 500px; margin-left: 5%;">

- Color presets for fibers

<img src="htdocs/doc/color_presets.png" style="width: 292px; margin-left: 5%; vertical-align: middle;">
<img src="htdocs/doc/color_preset_creation.png" style="width: 232px; vertical-align: middle;">

- Multimode fiber cable

<img src="htdocs/doc/multimode.jpg" style="width: 414px; margin-left: 5%;">

- Path tracing between two points. It also calculates the total length of cables along the path. Right click on a connector, select "start path point" and then "end path point". Right click on an empty space of the scheme and select "path"

<img src="htdocs/doc/trace.png" style="width: 800px; margin-left: 5%;">

- Bookmarks remember position and scale of a scheme fragment

<img src="htdocs/doc/bookmarks.png" style="margin-left: 5%;">

- Scheme data
  - Tags can be assigned to objects on the scheme. Using <img src="htdocs/doc/tags_button.png" style="vertical-align: middle;"> button, you can show objects with specified tags
  - A scheme may show some data (for example rx or tx) received from another database. For example, this may be a database in which you record ONU signal levels online.

<img src="htdocs/doc/scheme_data.png" style="width: 400px; margin-left: 5%;">
