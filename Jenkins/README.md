### Maven Installation & Configuration

To install Maven, follow these steps:

1. **Download the Maven Binary:**  
   Visit the [Apache Maven download page](https://maven.apache.org/download.cgi) and download the latest version in binary zip format.

2. **Extract the Archive:**  
   Unzip the downloaded file to the directory where you want to install Maven.

3. **Configure Environment Variables:**  
   Set the `M2_HOME` environment variable to the Maven installation directory, and add `${M2_HOME}/bin` to the `PATH` variable. This allows you to run Maven from the command line.
   - **On Windows:**  
     ```
     setx M2_HOME "C:\path\to\maven"
     setx PATH "%PATH%;%M2_HOME%\bin"
     ```
   - **On Linux/Mac:**  
     ```
     export M2_HOME=/path/to/maven
     export PATH=$PATH:$M2_HOME/bin
     ```

4. **Verify Installation:**  
   To verify that Maven was installed correctly, open a new command line window and type:
   ```
   mvn -v
   ```
   This command should output the installed Maven version along with the Java version and other information.

5. **Configuration:**  
   Configure your `settings.xml` file located in the `M2_HOME/conf` directory to manage your repository and build configurations, including proxies, server configurations, and profiles.

6. **Using Maven:**  
   Start creating your Maven projects using the `mvn archetype:generate` command to scaffold your new applications.

Ensure that your Java version is compatible with the Maven version you are using, and consult the [Maven documentation](https://maven.apache.org/guides/index.html) for more detailed guidelines and best practices.
