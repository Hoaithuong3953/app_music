import unittest
import time
from appium import webdriver
from appium.options.android import UiAutomator2Options
from appium.webdriver.common.appiumby import AppiumBy
from selenium.common.exceptions import WebDriverException, NoSuchElementException, TimeoutException, InvalidSessionIdException
from selenium.webdriver.support.ui import WebDriverWait
from selenium.webdriver.support import expected_conditions as EC
from openpyxl import Workbook, load_workbook
from datetime import datetime
import os
import requests

capabilities = {
    "platformName": "Android",
    "appium:automationName": "uiautomator2",
    "appium:deviceName": "emulator-5554",
    "appium:appPackage": "com.example.app_music",
    "appium:appActivity": ".MainActivity",
    "appium:language": "en",
    "appium:locale": "US",
    "appium:newCommandTimeout": 300,
    "appium:noReset": False
}

appium_server_url = 'http://127.0.0.1:4723/wd/hub'

class SearchMusicTest(unittest.TestCase):
    def setUp(self) -> None:
        print("🔄 Đang khởi động Appium driver...")
        max_attempts = 3
        attempt = 1
        self.driver = None

        # Dọn dẹp phiên cũ
        try:
            requests.delete(f'{appium_server_url}/session/{capabilities.get("sessionId", "")}')
        except Exception as e:
            print(f"⚠️ Không thể xóa phiên cũ: {e}")

        # Thử lại khởi động driver
        while attempt <= max_attempts and not self.driver:
            try:
                options = UiAutomator2Options().load_capabilities(capabilities)
                self.driver = webdriver.Remote(appium_server_url, options=options)
                time.sleep(5)
                print("✅ Driver đã khởi động thành công.")
                break
            except (WebDriverException, InvalidSessionIdException) as e:
                print(f"❌ Lỗi khi khởi động driver (lần {attempt}/{max_attempts}): {e}")
                attempt += 1
                time.sleep(2)
                if attempt > max_attempts:
                    print("❌ Không thể khởi động driver sau nhiều lần thử.")
                    self.driver = None
                    raise

        # Chuẩn bị thư mục và file Excel
        self.excel_dir = "result"
        self.excel_file = os.path.join(self.excel_dir, "result.xlsx")
        self.init_excel()

    def init_excel(self):
        """Khởi tạo thư mục result và file Excel nếu chưa tồn tại"""
        if not os.path.exists(self.excel_dir):
            os.makedirs(self.excel_dir)
            print(f"✅ Đã tạo thư mục: {self.excel_dir}")

        if not os.path.exists(self.excel_file):
            wb = Workbook()
            ws = wb.active
            ws.title = "Search Results"
            ws.append(["Test Case", "Search Query", "Result", "Status", "Timestamp"])
            wb.save(self.excel_file)
        print(f"✅ File Excel: {self.excel_file}")

    def save_to_excel(self, test_case, query, result, status):
        """Lưu kết quả vào file Excel"""
        try:
            wb = load_workbook(self.excel_file)
            ws = wb["Search Results"]
            timestamp = datetime.now().strftime("%Y-%m-%d %H:%M:%S")
            ws.append([test_case, query, result, status, timestamp])
            wb.save(self.excel_file)
            print(f"✅ Đã lưu kết quả vào Excel: {test_case}, {query}, {result}, {status}")
        except Exception as e:
            print(f"⚠️ Lỗi khi lưu vào Excel: {e}")

    def tearDown(self) -> None:
        if self.driver:
            try:
                self.driver.quit()
                print("✅ Đã đóng driver.")
            except (WebDriverException, InvalidSessionIdException) as e:
                print(f"⚠️ Không thể đóng driver: {e}")
        else:
            print("⚠️ Không có driver để đóng.")

    def restart_app(self):
        """Khởi động lại ứng dụng nếu cần"""
        try:
            self.driver.terminate_app('com.example.app_music')
            self.driver.activate_app('com.example.app_music')
            time.sleep(5)
            print("✅ Đã khởi động lại ứng dụng.")
        except Exception as e:
            print(f"❌ Lỗi khi khởi động lại ứng dụng: {e}")
            raise

    def test_sequential_search(self):
        """Tìm kiếm lần lượt Đánh đổi, Fly me to the moon, Obito và lưu kết quả vào Excel"""
        if not self.driver:
            self.fail("❌ Driver chưa được khởi động.")

        search_queries = ["Đánh đổi", "Fly me to the moon", "Obito"]

        for query in search_queries:
            try:
                # Tìm thanh tìm kiếm
                search_field = WebDriverWait(self.driver, 10).until(
                    EC.element_to_be_clickable((AppiumBy.XPATH, "//android.widget.EditText[@text='Search music']")),
                    message=f"Không tìm thấy thanh tìm kiếm cho query: {query}"
                )
                search_field.click()
                search_field.clear()
                search_field.send_keys(query)
                time.sleep(1)
                search_text = search_field.get_attribute("text")
                print(f"✅ Đã nhập tìm kiếm: {search_text}")
                self.assertEqual(search_text, query, f"Tìm kiếm không được nhập đúng cho query: {query}")

                # Nhấn nút tìm kiếm trên bàn phím
                self.driver.press_keycode(66)  # Keycode cho phím Enter trên Android
                time.sleep(3)

                # Kiểm tra kết quả tìm kiếm
                try:
                    result_elements = WebDriverWait(self.driver, 10).until(
                        EC.presence_of_all_elements_located((AppiumBy.XPATH, "//android.widget.TextView[contains(@text, 'Search Results')]")),
                        message=f"Không tìm thấy kết quả cho query: {query}"
                    )
                    result_count = len(self.driver.find_elements(AppiumBy.XPATH, "//android.widget.ListView/android.view.ViewGroup"))
                    result = f"Tìm thấy {result_count} kết quả cho '{query}'"
                    status = "PASSED"
                    print(f"✅ {result}")
                except TimeoutException:
                    result = f"Không tìm thấy kết quả cho '{query}'"
                    status = "FAILED"
                    print(f"⚠️ {result}")

                # Lưu kết quả vào Excel
                self.save_to_excel(
                    test_case="Sequential Search",
                    query=query,
                    result=result,
                    status=status
                )

            except (NoSuchElementException, TimeoutException) as e:
                print("🔍 In cấu trúc giao diện để debug:")
                print(self.driver.page_source)
                self.save_to_excel(
                    test_case="Sequential Search",
                    query=query,
                    result=f"Lỗi: {str(e)}",
                    status="FAILED"
                )
                self.fail(f"❌ Lỗi cho query '{query}': {e}")
            except InvalidSessionIdException as e:
                print("🔍 Session không hợp lệ, thử khởi động lại ứng dụng...")
                self.restart_app()
                self.fail(f"❌ Session không hợp lệ cho query '{query}': {e}")
            except Exception as e:
                print("🔍 In cấu trúc giao diện để debug:")
                print(self.driver.page_source)
                self.save_to_excel(
                    test_case="Sequential Search",
                    query=query,
                    result=f"Lỗi: {str(e)}",
                    status="FAILED"
                )
                self.fail(f"❌ Lỗi không xác định cho query '{query}': {e}")

if __name__ == '__main__':
    unittest.main(verbosity=2)