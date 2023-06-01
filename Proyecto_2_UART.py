import sys
from PyQt5.QtWidgets import QApplication, QWidget, QVBoxLayout, QLabel, QPushButton
from PyQt5.QtCore import QTimer
import serial
import time

class AppWindow(QWidget):
    def __init__(self):
        super().__init__()

        self.ser = serial.Serial('COM3', 9600, timeout=1)
        self.initUI()

    def initUI(self):
        self.setWindowTitle('PIC16F887 Interface')

        layout = QVBoxLayout()

        self.counter_label = QLabel('Ingrese la posición (18 - 23 - 28)')
        layout.addWidget(self.counter_label)

        self.derecha_button = QPushButton('derecha')
        self.derecha_button.clicked.connect(lambda: self.send_value(18))
        layout.addWidget(self.derecha_button)

        self.centro_button = QPushButton('centro')
        self.centro_button.clicked.connect(lambda: self.send_value(23))
        layout.addWidget(self.centro_button)

        self.izquierda_button = QPushButton('izquierda')
        self.izquierda_button.clicked.connect(lambda: self.send_value(28))
        layout.addWidget(self.izquierda_button)

        self.loco_button = QPushButton('loco')
        self.loco_button.clicked.connect(self.send_loco_sequence)
        layout.addWidget(self.loco_button)

        self.setLayout(layout)

        self.timer = QTimer()
        self.timer.timeout.connect(self.update_counter)
        self.timer.start(30)

    def send_value(self, value):
        value_as_byte = value.to_bytes(1, 'little')
        self.ser.write(value_as_byte)

    def send_loco_sequence(self):
        sequence = [15, 16, 17, 18, 20, 23, 25, 28, 25, 23, 20, 18, 17, 16, 15, 15, 16, 17, 18, 20, 23, 25, 28, 25, 23, 20, 18, 17, 16, 15, 16, 17, 18, 20, 23 ] 
        for numeric_value in sequence:
            value_as_byte = numeric_value.to_bytes(1, 'little')
            self.ser.write(value_as_byte)
            time.sleep(0.04)

    def update_counter(self):
        if self.ser.in_waiting:
            data = self.ser.readline().decode().strip()
            if data.isdigit():
                self.counter_label.setText(f'Counter: {data}')

if __name__ == '__main__':
    app = QApplication(sys.argv)
    window = AppWindow()
    window.show()
    sys.exit(app.exec_())
