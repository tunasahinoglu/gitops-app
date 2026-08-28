# Build the WAR from this repo's source, not from an external clone.
FROM maven:3.9.9-eclipse-temurin-21-jammy AS build

WORKDIR /build

# Copy the POM first so dependencies are cached separately from source changes.
COPY pom.xml .
RUN mvn dependency:go-offline -B

COPY src ./src
RUN mvn package -B -DskipTests

FROM tomcat:10-jdk21

RUN rm -rf /usr/local/tomcat/webapps/*

COPY --from=build /build/target/accounts-v2.war /usr/local/tomcat/webapps/ROOT.war

EXPOSE 8080

CMD ["catalina.sh", "run"]
