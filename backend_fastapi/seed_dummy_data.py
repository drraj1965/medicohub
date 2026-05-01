try:
    from .services import seed_if_needed
except ImportError:
    from services import seed_if_needed  # type: ignore


if __name__ == "__main__":
    seed_if_needed()
    print("Seeded MedicoHub dummy data.")
