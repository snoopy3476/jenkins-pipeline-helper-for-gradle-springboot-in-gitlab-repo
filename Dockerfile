FROM openjdk:11
WORKDIR /app
ENV PORT 8080
EXPOSE 8080
COPY target/*.jar /app/app.jar
ENTRYPOINT java $JAVA_OPTS -jar app.jar
