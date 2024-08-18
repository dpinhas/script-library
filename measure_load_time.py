#!/usr/bin/env python3

import sys
import time
from selenium import webdriver
from selenium.webdriver.chrome.service import Service
from webdriver_manager.chrome import ChromeDriverManager
from selenium.webdriver.common.desired_capabilities import DesiredCapabilities

def measure_load_time(url):
    # Set up the WebDriver (Chrome in this example)
    options = webdriver.ChromeOptions()
    options.add_argument("--headless")  # Run headless Chrome
    service = Service(ChromeDriverManager().install())
    driver = webdriver.Chrome(service=service, options=options)

    # Measure the page load time
    start_time = time.time()
    driver.get(url)
    end_time = time.time()

    load_time = end_time - start_time
    print(f"Page load time for {url}: {load_time:.2f} seconds")

    # Close the browser
    driver.quit()

if __name__ == "__main__":
    if len(sys.argv) != 2:
        print("Usage: python measure_load_time.py <url>")
        sys.exit(1)
    
    url = sys.argv[1]
    measure_load_time(url)

