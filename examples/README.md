# Example configurations for the Refactor server

This 'examples' directory contains the configuration files for a number of open source projects, detailed below.
The commit information points to the version of the sources that was used to generate the Refactor configuration files.

## GSON: example Maven project

Clone [https://github.com/google/gson](gson).

```
commit ff724a9860dec652a3eaefdb9d4c2772134b7159 (HEAD -> main, origin/main, origin/HEAD)
Author: Marcono1234 <Marcono1234@users.noreply.github.com>
Date:   Thu Sep 11 22:36:42 2025 +0200
```
I had to add

```
<dependency>
   <groupId>org.hamcrest</groupId>
    <artifactId>hamcrest</artifactId>
    <version>2.2</version>
    <scope>test</scope>
</dependency>
```
to tho 'pom.xml`'s dependency section to be able to compile the project.
Note: cannot compile with the Java 24+ needed to start the Refactor server, so point `JAVA_HOME` to a lower version JDK.

## JEDIS: example Maven project

Clone [https://github.com/redis/jedis](jedis).

```
commit d6baa758a3f85089383b8a1fa0585e9bfddd7b88 (HEAD -> master, origin/master, origin/HEAD)
Author: dependabot[bot] <49699333+dependabot[bot]@users.noreply.github.com>
Date:   Tue Sep 23 07:38:25 2025 +0300
```

## CONDUCTOR: example Gradle project

Clone [https://github.com/conductor-oss/conductor](conductor-oss).

```
commit dc1f57c09192a36ea4cbee880d84d5380de765ac (HEAD -> main, origin/main, origin/HEAD)
Merge: 919c416f6 b47d6271a
Author: Dale Brady <49766562+bradyyie@users.noreply.github.com>
Date:   Mon Sep 15 11:14:24 2025 -0400
```

## SPRING-CORE: example Gradle project

Clone [https://github.com/spring-projects/spring-framework](spring-framework).
Link in 'spring-framework/spring-core' in the 'projects' directory of the refactor server.
Enter the `build.*` properties by hand, because the `discover` command cannot detect this Gradle build implementation.

```
commit 77140da643c0351ea49c78990286e50020740f19 (HEAD, tag: v6.1.19)
Author: Brian Clozel <brian.clozel@broadcom.com>
Date:   Thu Apr 17 08:41:38 2025 +0200
```

