# iF.SVNAdmin SVN Server ( svnadmin )

This container provides a fully fonctionnal subversion server with iF.SVNAdmin as web based GUI.

This build is based on ubuntu/apache2:2.4-20.04_beta with php 7.4, mod ssl,  and iF.SVNAdmin 1.6.2 (svnadmin).

*This isn't an official build and it comes with no warranty  ...*

## How to run
```shell
docker run --name svnserver  -p 8080:80 -p 8443:443  -v /localdir/svn:/var/svn/ -v /localdir/keys:/etc/apache2/keys/ -v /localdir/dav_svn:/etc/apache2/dav_svn/ -d clamy54/docker-svn-svnadmin:tag
```

If /localdir/keys is empty, self-signed ssl certificate will be generated.
If /localdir/dav_svn is empty, a new admin account will be created (login : admin, password : admin).

You can access to the web gui on tcp port 8080 (http) or 443 (https)

You can acces svn repositories at https://my-svn-server:8443/svn/repository_name/

Example :

```shell
svn checkout --username myuser https://my-svn-server:8443/svn/myrepository ./
```


## Using external CA signed ssl certificate

Stop the container.
Copy your CA certificate to /localdir/keys/ca.pem
Copy your certificate to /localdir/keys/cert.pem
Copy your private key to /localdir/keys/cert.key


##  Volumes
To persist data, theses volumes are exposed and can be mounted to the local filesystem by adding -v option in the command line :

* `/var/svn` - Subversion repositories
* `/etc/apache2/keys/ ` - SSL keys & certificates
* `/etc/apache2/dav_svn/` - Users & authorization files used by mod_dav_svn

## Source repository 
https://github.com/clamy54/docker-svn-iF.SVNAdmin

## Example of how to use this container on Synology DSM :
https://www.be-root.com/2021/11/25/synology-et-serveur-svn/

