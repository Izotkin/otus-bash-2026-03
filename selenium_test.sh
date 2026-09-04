#!/bin/bash

if [[ $# -ne 3 ]]; then
    echo "Необходимо указать URL, браузер и версию"
    echo "Пример: $0 https://www.yandex.ru chrome 151.0"
    exit 1
fi

url="$1"
browser="$2"
version="$3"

if ! curl -s --max-time 3 "http://localhost:4444/wd/hub/status" > /dev/null; then
    echo "Selenium Grid недоступен по адресу http://localhost:4444/wd/hub"
    exit 1
fi

if ! command -v mvn &> /dev/null; then
    echo "Maven не установлен"
    exit 1
fi

tmp_dir=$(mktemp -d)
if [[ $? -ne 0 ]]; then
    echo "Не удалось создать временную директорию"
    exit 1
fi

cd "$tmp_dir" || exit 1

cat > pom.xml << 'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<project>
    <modelVersion>4.0.0</modelVersion>
    <groupId>com.test</groupId>
    <artifactId>selenium-test</artifactId>
    <version>1.0</version>

    <properties>
        <maven.compiler.source>11</maven.compiler.source>
        <maven.compiler.target>11</maven.compiler.target>
        <project.build.sourceEncoding>UTF-8</project.build.sourceEncoding>
    </properties>

    <dependencies>
        <dependency>
            <groupId>org.seleniumhq.selenium</groupId>
            <artifactId>selenium-java</artifactId>
            <version>4.27.0</version>
        </dependency>
        <dependency>
            <groupId>org.testng</groupId>
            <artifactId>testng</artifactId>
            <version>7.8.0</version>
            <scope>test</scope>
        </dependency>
    </dependencies>
    <build>
        <plugins>
            <plugin>
                <groupId>org.apache.maven.plugins</groupId>
                <artifactId>maven-surefire-plugin</artifactId>
                <version>3.2.2</version>
            </plugin>
        </plugins>
    </build>
</project>
EOF

mkdir -p src/test/java

cat > src/test/java/SeleniumTest.java << 'EOF'
import org.openqa.selenium.WebDriver;
import org.openqa.selenium.chrome.ChromeOptions;
import org.openqa.selenium.firefox.FirefoxOptions;
import org.openqa.selenium.edge.EdgeOptions;
import org.openqa.selenium.remote.RemoteWebDriver;
import org.testng.annotations.Test;
import java.net.URL;
import java.time.Duration;

public class SeleniumTest {
    @Test
    public void testOpenUrl() throws Exception {
        URL seleniumUrl = new URL("http://localhost:4444/wd/hub");
        WebDriver driver;

        String browser = System.getProperty("browser", "chrome");
        String version = System.getProperty("version", "151.0");
        String url = System.getProperty("url", "https://www.yandex.ru");

        System.out.println("Запуск теста");
        System.out.println("  Браузер: " + browser + " " + version);
        System.out.println("  URL: " + url);

        switch (browser.toLowerCase()) {
            case "chrome":
                ChromeOptions chromeOptions = new ChromeOptions();
                chromeOptions.setBrowserVersion(version);
                chromeOptions.setImplicitWaitTimeout(Duration.ofSeconds(10));
                driver = new RemoteWebDriver(seleniumUrl, chromeOptions);
                break;
            case "firefox":
                FirefoxOptions firefoxOptions = new FirefoxOptions();
                firefoxOptions.setBrowserVersion(version);
                firefoxOptions.setImplicitWaitTimeout(Duration.ofSeconds(10));
                driver = new RemoteWebDriver(seleniumUrl, firefoxOptions);
                break;
            case "edge":
                EdgeOptions edgeOptions = new EdgeOptions();
                edgeOptions.setBrowserVersion(version);
                edgeOptions.setImplicitWaitTimeout(Duration.ofSeconds(10));
                driver = new RemoteWebDriver(seleniumUrl, edgeOptions);
                break;
            default:
                throw new IllegalArgumentException("Неподдерживаемый браузер: " + browser);
        }

        try {
            driver.get(url);
            System.out.println("Заголовок: " + driver.getTitle());
            System.out.println("Текущий URL: " + driver.getCurrentUrl());
            System.out.println("Тест пройден успешно!");
        } finally {
            driver.quit();
        }
    }
}
EOF

echo "Запуск тестов для браузера: $browser $version"
echo "Тестируемый URL: $url"
echo ""

mvn clean test -Dbrowser="$browser" -Dversion="$version" -Durl="$url"

MAVEN_EXIT=$?

if [[ -d "target/surefire-reports" ]]; then

    for report in target/surefire-reports/*.txt; do
        if [[ -f "$report" ]]; then
            echo "Отчет: $report"
            cat "$report"
            echo ""
        fi
    done

    for report in target/surefire-reports/*.xml; do
        if [[ -f "$report" ]]; then
            echo "Отчет: $report"
            grep -E "tests=|failures=|errors=" "$report" | head -1
            echo ""
        fi
    done
fi

if [[ $MAVEN_EXIT -eq 0 ]]; then
    echo "Все тесты выполнены успешно!"
else
    echo "Тесты завершились с ошибкой (код: $MAVEN_EXIT)"
fi

cd /tmp
rm -rf "$tmp_dir"

exit $MAVEN_EXIT