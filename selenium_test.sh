#!/bin/bash

if [[ $# -ne 3 ]]; then
    echo "Необходимо указать URL, браузер и версию"
    echo "Пример: $0 http://localhost:8080 chrome 124.0"
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
    <dependencies>
        <dependency>
            <groupId>org.seleniumhq.selenium</groupId>
            <artifactId>selenium-java</artifactId>
            <version>3.141.59</version>
        </dependency>
        <dependency>
            <groupId>org.testng</groupId>
            <artifactId>testng</artifactId>
            <version>6.14.3</version>
            <scope>test</scope>
        </dependency>
    </dependencies>
</project>
EOF

mkdir -p src/test/java
cat > src/test/java/SeleniumTest.java << EOF
import org.openqa.selenium.WebDriver;
import org.openqa.selenium.remote.DesiredCapabilities;
import org.openqa.selenium.remote.RemoteWebDriver;
import org.testng.annotations.Test;
import java.net.URL;

public class SeleniumTest {
    @Test
public void testOpenUrl() throws Exception {
        DesiredCapabilities caps = new DesiredCapabilities();
        caps.setBrowserName("$browser");
        caps.setVersion("$version");

        WebDriver driver = new RemoteWebDriver(
            new URL("http://localhost:4444/wd/hub"), caps
        );

        driver.get("$url");
        System.out.println("Заголовок: " + driver.getTitle());
        driver.quit();
    }
}
EOF

mvn clean test

if [[ $? -eq 0 ]]; then
    echo "Тесты выполнены успешно"
    if [[ -d "target/surefire-reports" ]]; then
        echo "Результаты тестов:"
        find target/surefire-reports -name "*.xml" | while read r; do
            echo "  $r"
            grep -E "tests=|failures=" "$r" | head -1
        done
    fi
else
    echo "Ошибка при выполнении тестов"
    exit 1
fi

cd /tmp
rm -rf "$tmp_dir"