mkdir("build");
mkdir("build/classes");
mkdir("build/sources");
mkdir("build/javadoc");

javac("src/main/java", "build/classes");
copy("src/main/resources", "build/classes");
copy("src/main/java", "build/sources");
copy("src/main/javadoc", "build/sources");
javadoc("build/sources", "build/javadoc");

mkdir("dist");
var name = "snuggletex-core";
jar("dist/" + name + ".jar", "build/classes");
jar("dist/" + name + "-source.jar", "build/sources");
jar("dist/" + name + "-javadoc.jar", "build/javadoc");
cp("pom.xml", "dist/" + name + ".pom")

publish("dist")
