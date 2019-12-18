## A blockset mod for SmoothWall

#### Fetch
```
cd /var/smoothwall
mkdir mods-available
cd mods-available
```
```
wget https://github.com/ShorTie8/blocksets/archive/master.tar.gz
tar -xvf master.tar.gz
```
or
```
git clone https://github.com/ShorTie8/blocksets
```

#### Install the mod
Set ownership, permissions and creates symlinks.
```
cd blocksets
./install.mod
```

#### Start manually after activation
```
blockset start
```

#### Stop manually
```
blockset stop
```

#### Deactivate mod
```
/var/smoothwall/mods/blocksets/deact.mod
```

#### Uninstall/Delete .. ;(~
First save your settings and sites files, if desired.
```
rm -rf /var/smoothwall/mods-available/blocksets.
```
