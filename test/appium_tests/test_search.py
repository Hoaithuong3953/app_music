import unittest
import time
import logging
from appium import webdriver
from appium.options.android import UiAutomator2Options
from appium.webdriver.common.appiumby import AppiumBy
from selenium.common.exceptions import TimeoutException, NoSuchElementException
from selenium.webdriver.support.ui import WebDriverWait
from selenium.webdriver.support import expected_conditions as EC
from openpyxl import Workbook, load_workbook
from datetime import datetime
import os

# Thiết lập logging
logging.basicConfig(
    filename="test_search.log",
    level=logging.INFO,
    format="%(asctime)s - %(levelname)s - %(message)s"
)
logger = logging.getLogger()

class SearchMusicTest(unittest.TestCase):
    def setUp(self):
        """Khởi tạo Appium driver trước mỗi test case"""
        print("🔄 Đang khởi động Appium driver...")
        logger.info("Đang khởi động Appium driver...")
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
        logger.info("Driver đã khởi động thành công.")

        # Chuẩn bị thư mục và file Excel
        self.excel_dir = "result"
        self.excel_file = os.path.join(self.excel_dir, "Search.xlsx")
        self.init_excel()

    def init_excel(self):
        """Khởi tạo thư mục result và file Excel nếu chưa tồn tại"""
        if not os.path.exists(self.excel_dir):
            os.makedirs(self.excel_dir)
            print(f"✅ Đã tạo thư mục: {self.excel_dir}")
            logger.info(f"Đã tạo thư mục: {self.excel_dir}")

        if not os.path.exists(self.excel_file):
            wb = Workbook()
            ws = wb.active
            ws.title = "Search Results"
            ws.append(["Test Id", "Search Query", "Result", "Status", "Timestamp"])
            wb.save(self.excel_file)
        print(f"✅ File Excel: {self.excel_file}")
        logger.info(f"File Excel: {self.excel_file}")

    def save_to_excel(self, test_Id, query, result, status):
        """Lưu kết quả vào file Excel"""
        try:
            wb = load_workbook(self.excel_file)
            ws = wb["Search Results"]
            timestamp = datetime.now().strftime("%Y-%m-%d %H:%M:%S")
            ws.append([test_Id, query, result, status, timestamp])
            wb.save(self.excel_file)
            print(f"✅ Đã lưu kết quả vào Excel: {test_Id}, {query}, {result}, {status}")
            logger.info(f"Đã lưu kết quả vào Excel: {test_Id}, {query}, {result}, {status}")
        except Exception as e:
            print(f"⚠️ Lỗi khi lưu vào Excel: {e}")
            logger.error(f"Lỗi khi lưu vào Excel: {e}")

    def login(self):
        """Đăng nhập vào ứng dụng"""
        try:
            print("🔍 Bắt đầu đăng nhập...")
            logger.info("Bắt đầu đăng nhập...")
            email_field = self.wait.until(
                EC.presence_of_all_elements_located((AppiumBy.CLASS_NAME, "android.widget.EditText"))
            )[0]
            email_field.click()
            email_field.clear()
            email_field.send_keys("khai@gmail.com")
            time.sleep(1)
            print("✅ Đã nhập email.")
            logger.info("Đã nhập email.")

            password_field = self.wait.until(
                EC.presence_of_all_elements_located((AppiumBy.CLASS_NAME, "android.widget.EditText"))
            )[1]
            password_field.click()
            password_field.clear()
            password_field.send_keys("123456")
            time.sleep(1)
            print("✅ Đã nhập mật khẩu.")
            logger.info("Đã nhập mật khẩu.")

            self.driver.hide_keyboard()
            time.sleep(1)
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
            logger.info("Đã nhấn nút Login.")

            self.wait.until(
                EC.presence_of_element_located((AppiumBy.XPATH, "//*[contains(@content-desc, 'Hi,')]")),
                message="Không tìm thấy tiêu đề HomeScreen"
            )
            time.sleep(2)
            print("✅ Đã vào màn hình chính.")
            logger.info("Đã vào màn hình chính.")
            print("🔍 Giao diện màn hình chính:")
            logger.info("Giao diện màn hình chính:")
            print(self.driver.page_source)
            logger.info(self.driver.page_source)
        except Exception as e:
            print("🔍 In cấu trúc giao diện để debug:")
            logger.info("In cấu trúc giao diện để debug:")
            print(self.driver.page_source)
            logger.info(self.driver.page_source)
            self.fail(f"❌ Lỗi đăng nhập: {e}")
            logger.error(f"Lỗi đăng nhập: {e}")

    def ensure_app_active(self):
        """Đảm bảo ứng dụng đang ở trạng thái hoạt động"""
        current_activity = self.driver.current_activity
        if current_activity != ".MainActivity":
            print(f"⚠️ Ứng dụng không ở trạng thái mong muốn: {current_activity}. Khởi động lại...")
            logger.warning(f"Ứng dụng không ở trạng thái mong muốn: {current_activity}. Khởi động lại...")
            self.driver.activate_app("com.example.app_music")
            time.sleep(5)
            self.wait.until(
                EC.presence_of_element_located((AppiumBy.XPATH, "//*[contains(@content-desc, 'Hi,')]")),
                message="Không thể quay lại màn hình chính"
            )
            print("✅ Đã khởi động lại ứng dụng.")
            logger.info("Đã khởi động lại ứng dụng.")

    def search_and_check(self, query, test_case):
        """Tìm kiếm và kiểm tra kết quả, lưu vào Excel"""
        try:
            print(f"🔍 Đang kiểm tra trạng thái ứng dụng trước khi tìm kiếm '{query}'...")
            logger.info(f"Đang kiểm tra trạng thái ứng dụng trước khi tìm kiếm '{query}'...")
            self.ensure_app_active()
            current_activity = self.driver.current_activity
            print(f"✅ Trạng thái ứng dụng: {current_activity}")
            logger.info(f"Trạng thái ứng dụng: {current_activity}")

            print(f"🔍 Đang tìm thanh tìm kiếm cho '{query}'...")
            logger.info(f"Đang tìm thanh tìm kiếm cho '{query}'...")
            search_field = self.wait.until(
                EC.element_to_be_clickable(
                    (AppiumBy.XPATH, "//android.widget.ScrollView//android.widget.EditText")
                ),
                message="Không tìm thấy thanh tìm kiếm"
            )
            print(f"🔍 Thuộc tính thanh tìm kiếm: enabled={search_field.is_enabled()}, displayed={search_field.is_displayed()}")
            logger.info(f"Thuộc tính thanh tìm kiếm: enabled={search_field.is_enabled()}, displayed={search_field.is_displayed()}")

            if not search_field.is_enabled() or not search_field.is_displayed():
                raise Exception("Thanh tìm kiếm không ở trạng thái có thể tương tác.")

            print("🔍 Giao diện trước khi nhấn thanh tìm kiếm:")
            logger.info("Giao diện trước khi nhấn thanh tìm kiếm:")
            print(self.driver.page_source)
            logger.info(self.driver.page_source)

            search_field.click()
            time.sleep(1)
            print("✅ Đã nhấn vào thanh tìm kiếm.")
            logger.info("Đã nhấn vào thanh tìm kiếm.")

            search_field.clear()
            print(f"✅ Đã xóa nội dung cũ trong thanh tìm kiếm trước khi nhập '{query}'.")
            logger.info(f"Đã xóa nội dung cũ trong thanh tìm kiếm trước khi nhập '{query}'.")

            print(f"🔍 Đang nhập '{query}' vào thanh tìm kiếm...")
            logger.info(f"Đang nhập '{query}' vào thanh tìm kiếm...")
            try:
                self.driver.execute_script("mobile: shell", {"command": f"input text '{query}'"})
                print(f"✅ Đã nhập '{query}' bằng ADB.")
                logger.info(f"Đã nhập '{query}' bằng ADB.")
            except Exception as e:
                print(f"⚠️ Lỗi khi nhập bằng ADB, thử nhập từng ký tự: {e}")
                logger.warning(f"Lỗi khi nhập bằng ADB, thử nhập từng ký tự: {e}")
                for char in query:
                    search_field.send_keys(char)
                    time.sleep(0.3)
                    current_activity = self.driver.current_activity
                    if not current_activity:
                        raise Exception(f"Ứng dụng đã thoát khi nhập ký tự '{char}'.")
                    print(f"✅ Đã nhập ký tự: {char}")
                    logger.info(f"Đã nhập ký tự: {char}")
                print(f"✅ Đã nhập '{query}' bằng từng ký tự.")
                logger.info(f"Đã nhập '{query}' bằng từng ký tự.")

            current_activity = self.driver.current_activity
            if not current_activity:
                raise Exception("Ứng dụng đã thoát sau khi nhập thông tin.")
            print(f"✅ Trạng thái ứng dụng sau khi nhập: {current_activity}")
            logger.info(f"Trạng thái ứng dụng sau khi nhập: {current_activity}")

            print("🔍 Giao diện sau khi nhập thông tin:")
            logger.info("Giao diện sau khi nhập thông tin:")
            print(self.driver.page_source)
            logger.info(self.driver.page_source)

            # Bỏ ẩn bàn phím
            print("⚠️ Bỏ bước ẩn bàn phím để kiểm tra lỗi thoát.")
            logger.info("Bỏ bước ẩn bàn phím để kiểm tra lỗi thoát.")

            time.sleep(2)  # Giảm thời gian chờ xuống 2 giây
            current_activity = self.driver.current_activity
            if not current_activity:
                raise Exception("Ứng dụng đã thoát sau khi chờ.")
            print(f"✅ Đã chờ 2 giây sau khi nhập '{query}'. Trạng thái: {current_activity}")
            logger.info(f"Đã chờ 2 giây sau khi nhập '{query}'. Trạng thái: {current_activity}")

            # Kiểm tra kết quả tìm kiếm
            print("🔍 Kiểm tra kết quả tìm kiếm...")
            logger.info("Kiểm tra kết quả tìm kiếm...")
            try:
                result_element = self.wait.until(
                    EC.presence_of_element_located(
                        (AppiumBy.XPATH, f"//*[contains(@content-desc, '{query}') or contains(@text, '{query}') or contains(., '{query}')]")
                    ),
                    message=f"Không tìm thấy kết quả cho '{query}'"
                )
                result_text = (
                        result_element.get_attribute("content-desc") or
                        result_element.get_attribute("text") or
                        "Không xác định"
                )
                print(f"✅ Kết quả tìm kiếm: {result_text}")
                logger.info(f"Kết quả tìm kiếm: {result_text}")
                self.assertIn(query.lower(), result_text.lower(), f"Kết quả không chứa '{query}'")
                status = "PASSED"

                # Xóa nội dung thanh tìm kiếm sau khi có kết quả
                print(f"🔍 Xóa nội dung thanh tìm kiếm sau khi có kết quả cho '{query}'...")
                logger.info(f"Xóa nội dung thanh tìm kiếm sau khi có kết quả cho '{query}'...")
                current_activity = self.driver.current_activity
                if not current_activity:
                    raise Exception("Ứng dụng đã thoát trước khi xóa thanh tìm kiếm.")
                if not (search_field.is_enabled() and search_field.is_displayed()):
                    raise Exception("Thanh tìm kiếm không ở trạng thái có thể tương tác để xóa.")
                search_field.click()
                time.sleep(1)
                search_field.clear()
                print(f"✅ Đã xóa nội dung thanh tìm kiếm sau khi có kết quả.")
                logger.info("Đã xóa nội dung thanh tìm kiếm sau khi có kết quả.")

            except TimeoutException:
                print(f"⚠️ Không tìm thấy kết quả, kiểm tra trạng thái 'No results found'...")
                logger.info("Không tìm thấy kết quả, kiểm tra trạng thái 'No results found'...")
                no_result_element = self.wait.until(
                    EC.presence_of_element_located(
                        (AppiumBy.XPATH, "//*[contains(@content-desc, 'No results found')]")
                    ),
                    message="Không tìm thấy trạng thái 'No results found'"
                )
                result_text = no_result_element.get_attribute("content-desc")
                print(f"✅ Kết quả: {result_text}")
                logger.info(f"Kết quả: {result_text}")
                status = "PARTIAL (No results found)"

                # Xóa nội dung thanh tìm kiếm sau khi có trạng thái "No results found"
                print(f"🔍 Xóa nội dung thanh tìm kiếm sau khi có trạng thái 'No results found' cho '{query}'...")
                logger.info(f"Xóa nội dung thanh tìm kiếm sau khi có trạng thái 'No results found' cho '{query}'...")
                current_activity = self.driver.current_activity
                if not current_activity:
                    raise Exception("Ứng dụng đã thoát trước khi xóa thanh tìm kiếm.")
                if not (search_field.is_enabled() and search_field.is_displayed()):
                    raise Exception("Thanh tìm kiếm không ở trạng thái có thể tương tác để xóa.")
                search_field.click()
                time.sleep(1)
                search_field.clear()
                print(f"✅ Đã xóa nội dung thanh tìm kiếm sau khi có trạng thái 'No results found'.")
                logger.info("Đã xóa nội dung thanh tìm kiếm sau khi có trạng thái 'No results found'.")

            except Exception as e:
                raise Exception(f"Lỗi khi kiểm tra kết quả: {e}")

            self.save_to_excel(
                test_case=test_case,
                query=query,
                result=result_text,
                status=status
            )
        except Exception as e:
            print(f"⚠️ Lỗi khi tìm kiếm '{query}' (có thể ứng dụng đã thoát): {e}")
            logger.error(f"Lỗi khi tìm kiếm '{query}' (có thể ứng dụng đã thoát): {e}")
            print("🔍 In cấu trúc giao diện để debug:")
            logger.info("In cấu trúc giao diện để debug:")
            try:
                print(self.driver.page_source)
                logger.info(self.driver.page_source)
            except:
                print("⚠️ Không thể lấy page_source, ứng dụng đã crash.")
                logger.error("Không thể lấy page_source, ứng dụng đã crash.")
            self.save_to_excel(
                test_case=test_case,
                query=query,
                result=f"Lỗi: {str(e)}",
                status="FAILED"
            )
            self.fail(f"❌ Lỗi không xác định: {e}")

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
                logger.info("Đã đóng driver.")
            except Exception as e:
                print(f"⚠️ Không thể đóng driver: {e}")
                logger.error(f"Không thể đóng driver: {e}")

if __name__ == "__main__":
    unittest.main(verbosity=2)