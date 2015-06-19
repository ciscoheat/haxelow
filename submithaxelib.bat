@echo off
del haxelow.zip >nul 2>&1

cd src
copy ..\README.md .
zip -r ..\haxelow.zip .
del README.md
cd ..

haxelib submit haxelow.zip
del haxelow.zip
