from setuptools import setup

setup(
    name="proxmox-analyzer",
    version="1.0.0",
    description="Proxmox Health Check Analyzer",
    author="Proxmox Health Check Team",
    py_modules=["proxmox_analyzer"],
    install_requires=[
        "dataclasses>=0.8; python_version < '3.7'",
        "typing-extensions>=4.0.0",
    ],
    extras_require={
        "dev": [
            "pytest>=7.0.0",
            "ruff>=0.1.0",
            "mypy>=0.950",
        ],
        "viz": [
            "pandas>=1.3.0",
            "matplotlib>=3.5.0",
        ],
        "full": [
            "pandas>=1.3.0",
            "matplotlib>=3.5.0",
            "pyyaml>=6.0",
            "rich>=12.0.0",
        ],
    },
    python_requires=">=3.6",
)
