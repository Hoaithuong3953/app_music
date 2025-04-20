import unittest
import time
from appium import webdriver
from appium.options.android import UiAutomator2Options
from appium.webdriver.common.appiumby import AppiumBy
from selenium.common.exceptions import TimeoutException, NoSuchElementException, StaleElementReferenceException
from selenium.webdriver.support.ui import WebDriverWait
from selenium.webdriver.support import expected_conditions as EC
from openpyxl import Workbook, load_workbook
from datetime import datetime
import os

class SearchMusicTest(unittest.TestCase):
    def setUp(self):
        """Khởi tạo Appium driver trước mỗi test case"""
        print("🔄 Đang khởi động Appium driver...")
        desired_caps = {
            "platformName": "Android",
            "deviceName": "emulator-5554",
            "appPackage": "com.example.app_music",
            "appActivity": ".MainActivity",
            "automationName": "UiAutomator2",
            "newCommandTimeout": 300,
            "adbExecTimeout": 60000,
            "appWaitActivity": "*",
            "noReset": True,
            "fullReset": False,
            "language": "en",
            "locale": "US"
        }
        options = UiAutomator2Options().load_capabilities(desired_caps)
        self.driver = webdriver.Remote("http://127.0.0.1:4723/wd/hub", options=options)
        self.wait = WebDriverWait(self.driver, 40)
        self.driver.terminate_app("com.example.app_music")
        self.driver.activate_app("com.example.app_music")
        time.sleep(5)
        print("✅ Driver đã khởi động thành công.")

        # Chuẩn bị file Excel
        self.excel_file = r"D:\Nam3\hocky2\kiemthu_giuaky\app_music\test\appium_tests\search_results.xlsx"
        self.init_excel()

    def init_excel(self):
        """Khởi tạo file Excel nếu chưa tồn tại"""
        os.makedirs(os.path.dirname(self.excel_file), exist_ok=True)
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

    def ensure_app_foreground(self):
        """Đảm bảo ứng dụng ở foreground"""
        try:
            current_package = self.driver.current_package
            if current_package != 'com.example.app_music':
                print(f"⚠️ Ứng dụng không ở foreground: {current_package}. Kích hoạt lại...")
                self.driver.activate_app('com.example.app_music')
                time.sleep(3)
                self.wait.until(
                    EC.presence_of_element_located((AppiumBy.XPATH, "//*[contains(@content-desc, 'Hi,')]")),
                    message="Không trở lại HomeScreen"
                )
                print("✅ Đã trở lại ứng dụng.")
        except Exception as e:
            print(f"⚠️ Lỗi khi kiểm tra foreground: {e}")

    def login(self):
        """Đăng nhập vào ứng dụng"""
        try:
            print("🔍 Bắt đầu đăng nhập...")
            email_field = self.wait.until(
                EC.presence_of_all_elements_located((AppiumBy.CLASS_NAME, "android.widget.EditText"))
            )[0]
            email_field.click()
            email_field.clear()
            email_field.send_keys("khai@gmail.com")
            time.sleep(1)
            print("✅ Đã nhập email.")

            password_field = self.wait.until(
                EC.presence_of_all_elements_located((AppiumBy.CLASS_NAME, "android.widget.EditText"))
            )[1]
            password_field.click()
            password_field.clear()
            password_field.send_keys("123456")
            time.sleep(1)
            print("✅ Đã nhập mật khẩu.")

            try:
                if self.driver.is_keyboard_shown():
                    self.driver.hide_keyboard()
                    print("✅ Đã ẩn bàn phím.")
            except:
                print("⚠️ Không cần ẩn bàn phím.")

            self.driver.find_element(
                AppiumBy.ANDROID_UIAUTOMATOR,
                'new UiScrollable(new UiSelector().scrollable(true)).scrollIntoView('
                'new UiSelector().description("Login"))'
            )
            login_button = self.wait.until(
                EC.element_to_be_clickable((AppiumBy.XPATH, "//android.widget.Button[@content-desc='Login']"))
            )
            login_button.click()
            print("✅ Đã nhấn nút Login.")

            self.wait.until(
                EC.presence_of_element_located((AppiumBy.XPATH, "//*[contains(@content-desc, 'Hi,')]")),
                message="Không tìm thấy tiêu đề HomeScreen"
            )
            time.sleep(2)
            print("✅ Đã vào màn hình chính.")
        except Exception as e:
            print("🔍 In cấu trúc giao diện để debug:")
            print(self.driver.page_source)
            self.fail(f"❌ Lỗi đăng nhập: {e}")

    def search_and_check(self, query, test_case):
        """Tìm kiếm và kiểm tra kết quả, lưu vào Excel"""
        try:
            self.ensure_app_foreground()
            print(f"🔍 Đang kiểm tra các EditText trên màn hình cho '{query}'...")
            edit_texts = self.driver.find_elements(AppiumBy.CLASS_NAME, "android.widget.EditText")
            for i, elem in enumerate(edit_texts):
                print(f"EditText {i}: text={elem.get_attribute('text')}, "
                      f"content-desc={elem.get_attribute('content-desc')}, "
                      f"bounds={elem.get_attribute('bounds')}")

            print(f"🔍 Đang tìm thanh tìm kiếm cho '{query}'...")
            search_field = self.wait.until(
                EC.element_to_be_clickable(
                    (AppiumBy.XPATH, "//android.widget.ScrollView//android.widget.EditText")
                ),
                message="Không tìm thấy thanh tìm kiếm"
            )
            print(f"✅ Đã tìm thấy thanh tìm kiếm.")

            search_field.click()
            time.sleep(1)
            search_field.clear()
            print(f"✅ Đã xóa nội dung cũ trong thanh tìm kiếm.")
            search_field.send_keys(query)
            print(f"✅ Đã nhập '{query}'.")

            search_text = search_field.get_attribute("text")
            print(f"✅ Giá trị thanh tìm kiếm: {search_text}")
            self.assertEqual(search_text, query, f"Từ khóa '{query}' không được nhập đúng!")

            try:
                if self.driver.is_keyboard_shown():
                    self.driver.hide_keyboard()
                    print("✅ Đã ẩn bàn phím.")
            except:
                print("⚠️ Không cần ẩn bàn phím.")

            print(f"🔍 Đang chờ kết quả tìm kiếm cho '{query}'...")
            result_element = self.wait.until(
                EC.presence_of_element_located(
                    (AppiumBy.XPATH, f"//*[contains(@content-desc, '{query}') or contains(@text, '{query}')]")
                ),
                message=f"Không tìm thấy kết quả cho '{query}'"
            )
            result_text = result_element.get_attribute("content-desc") or result_element.get_attribute("text")
            print(f"✅ Kết quả tìm kiếm: {result_text}")
            self.assertIn(query, result_text, f"Kết quả không chứa '{query}'")

            self.save_to_excel(
                test_case=test_case,
                query=query,
                result=result_text,
                status="PASSED"
            )
        except TimeoutException:
            print(f"⚠️ Không tìm thấy kết quả cho '{query}'.")
            print("🔍 In cấu trúc giao diện để debug:")
            print(self.driver.page_source)
            self.save_to_excel(
                test_case=test_case,
                query=query,
                result="Không tìm thấy",
                status="FAILED"
            )
        except StaleElementReferenceException:
            print(f"⚠️ Thanh tìm kiếm không còn tồn tại khi tìm '{query}'.")
            print("🔍 In cấu trúc giao diện để debug:")
            print(self.driver.page_source)
            self.save_to_excel(
                test_case=test_case,
                query=query,
                result="StaleElement: Thanh tìm kiếm mất",
                status="FAILED"
            )
        except Exception as e:
            print(f"⚠️ Lỗi không xác định khi tìm kiếm '{query}'.")
            print("🔍 In cấu trúc giao diện để debug:")
            print(self.driver.page_source)
            self.save_to_excel(
                test_case=test_case,
                query=query,
                result=str(e),
                status="FAILED"
            )

    def test_sequential_search(self):
        """Tìm kiếm lần lượt Đánh đổi, Fly me to the moon, Obito và lưu kết quả vào Excel"""
        self.login()

        # Tìm kiếm "Đánh đổi"
        self.search_and_check("Đánh đổi", "Search Đánh đổi")

        # Tìm kiếm "Fly me to the moon"
        self.search_and_check("Fly me to the moon", "Search Fly me to the moon")

        # Tìm kiếm "Obito"
        self.search_and_check("Obito", "Search Obito")

    def tearDown(self):
        """Dọn dẹp sau mỗi test case"""
        if self.driver:
            try:
                self.driver.quit()
                print("✅ Đã đóng driver.")
            except Exception as e:
                print(f"⚠️ Không thể đóng driver: {e}")

if __name__ == "__main__":
    unittest.main(verbosity=2)