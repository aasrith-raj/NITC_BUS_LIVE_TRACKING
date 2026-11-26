-- MySQL dump 10.13  Distrib 8.0.23, for Win64 (x86_64)
--
-- Host: localhost    Database: nitc_bus_tracking
-- ------------------------------------------------------
-- Server version	8.0.23

/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!50503 SET NAMES utf8mb4 */;
/*!40103 SET @OLD_TIME_ZONE=@@TIME_ZONE */;
/*!40103 SET TIME_ZONE='+00:00' */;
/*!40014 SET @OLD_UNIQUE_CHECKS=@@UNIQUE_CHECKS, UNIQUE_CHECKS=0 */;
/*!40014 SET @OLD_FOREIGN_KEY_CHECKS=@@FOREIGN_KEY_CHECKS, FOREIGN_KEY_CHECKS=0 */;
/*!40101 SET @OLD_SQL_MODE=@@SQL_MODE, SQL_MODE='NO_AUTO_VALUE_ON_ZERO' */;
/*!40111 SET @OLD_SQL_NOTES=@@SQL_NOTES, SQL_NOTES=0 */;

--
-- Dumping data for table `announcements`
--

LOCK TABLES `announcements` WRITE;
/*!40000 ALTER TABLE `announcements` DISABLE KEYS */;
/*!40000 ALTER TABLE `announcements` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Dumping data for table `assignments`
--

LOCK TABLES `assignments` WRITE;
/*!40000 ALTER TABLE `assignments` DISABLE KEYS */;
INSERT INTO `assignments` VALUES (2,1,2,1,'2026-11-07');
/*!40000 ALTER TABLE `assignments` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Dumping data for table `breakdown_reports`
--

LOCK TABLES `breakdown_reports` WRITE;
/*!40000 ALTER TABLE `breakdown_reports` DISABLE KEYS */;
/*!40000 ALTER TABLE `breakdown_reports` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Dumping data for table `bus_locations`
--

LOCK TABLES `bus_locations` WRITE;
/*!40000 ALTER TABLE `bus_locations` DISABLE KEYS */;
/*!40000 ALTER TABLE `bus_locations` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Dumping data for table `buses`
--

LOCK TABLES `buses` WRITE;
/*!40000 ALTER TABLE `buses` DISABLE KEYS */;
INSERT INTO `buses` VALUES (1,' KL234 A 56',40,'ACTIVE');
/*!40000 ALTER TABLE `buses` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Dumping data for table `drivers`
--

LOCK TABLES `drivers` WRITE;
/*!40000 ALTER TABLE `drivers` DISABLE KEYS */;
INSERT INTO `drivers` VALUES (2,2,'string'),(3,6,'KL 57 26 0997');
/*!40000 ALTER TABLE `drivers` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Dumping data for table `route_stops`
--

LOCK TABLES `route_stops` WRITE;
/*!40000 ALTER TABLE `route_stops` DISABLE KEYS */;
INSERT INTO `route_stops` VALUES (1,1,3);
/*!40000 ALTER TABLE `route_stops` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Dumping data for table `routes`
--

LOCK TABLES `routes` WRITE;
/*!40000 ALTER TABLE `routes` DISABLE KEYS */;
INSERT INTO `routes` VALUES (1,'Main_gate - hostel ','Main_gate','hostel',1);
/*!40000 ALTER TABLE `routes` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Dumping data for table `schedules`
--

LOCK TABLES `schedules` WRITE;
/*!40000 ALTER TABLE `schedules` DISABLE KEYS */;
/*!40000 ALTER TABLE `schedules` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Dumping data for table `stops`
--

LOCK TABLES `stops` WRITE;
/*!40000 ALTER TABLE `stops` DISABLE KEYS */;
INSERT INTO `stops` VALUES (1,'NITC Main Gate',11.3210000,75.9340000),(3,'Library',-90.0000000,-180.0000000);
/*!40000 ALTER TABLE `stops` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Dumping data for table `users`
--

LOCK TABLES `users` WRITE;
/*!40000 ALTER TABLE `users` DISABLE KEYS */;
INSERT INTO `users` VALUES (2,'Test driver','driver@nitc.ac.in','pbkdf2_sha256$600000$B3AR5l6ZgCFOMiwRrRBr1w==$RNnu_x5BjKIRoMs_Q_ZxWc_H1WJ6To7s8jsvHS5_Srg=','DRIVER'),(3,'admin','admin@nitc.ac.in','pbkdf2_sha256$600000$yt6WfQs27EoHKw4jnJJvNg==$723yrNhxFxvqi7EQ4uPxf4lRBpH1RqfVSPMqEQrsqvY=','ADMIN'),(4,'vinay','vinny@nitc.ac.in','pbkdf2_sha256$600000$z32L-R8cwMnTc5OXf-qOEA==$ZgwtU-YdwOHwjUu2pi4ew_C6D3Lv5y7tqr2Kln6Gsog=','STUDENT'),(5,'Raj','aasrith_m260774cs@nitc.ac.in','pbkdf2_sha256$600000$AsIfnWdaECBFCm9o0zBQHg==$7KmIQ39MQ0wg8ByS8U3KDl1r9P9fo3ftuNlB2IfvEDQ=','ADMIN'),(6,'driver1','shruti_m260997cs@nitc.ac.in','pbkdf2_sha256$600000$hHRwIHBm10h4sEIit3E6JQ==$JtNV4ZO53GVMVMdinvPpPTYWthOLd9NTLjELAlIcToc=','DRIVER');
/*!40000 ALTER TABLE `users` ENABLE KEYS */;
UNLOCK TABLES;
/*!40103 SET TIME_ZONE=@OLD_TIME_ZONE */;

/*!40101 SET SQL_MODE=@OLD_SQL_MODE */;
/*!40014 SET FOREIGN_KEY_CHECKS=@OLD_FOREIGN_KEY_CHECKS */;
/*!40014 SET UNIQUE_CHECKS=@OLD_UNIQUE_CHECKS */;
/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
/*!40111 SET SQL_NOTES=@OLD_SQL_NOTES */;

-- Dump completed on 2026-11-14 14:02:29
