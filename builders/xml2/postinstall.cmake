############################################################################
# postinstall.cmake
# Copyright (C) 2014  Belledonne Communications, Grenoble France
#
############################################################################
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# as published by the Free Software Foundation; either version 2
# of the License, or (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA  02111-1307, USA.
#
############################################################################

if(EXISTS ${INSTALL_PREFIX}/lib/libxml2.dll.a)
	execute_process(COMMAND "${CMAKE_COMMAND}" "-E" "copy" "${INSTALL_PREFIX}/lib/libxml2.dll.a" "${INSTALL_PREFIX}/lib/xml2.lib")
endif()
if(EXISTS ${INSTALL_PREFIX}/lib/libxml2.a)
	execute_process(COMMAND "${CMAKE_COMMAND}" "-E" "copy" "${INSTALL_PREFIX}/lib/libxml2.a" "${INSTALL_PREFIX}/lib/xml2.lib")
endif()
execute_process(COMMAND "${CMAKE_COMMAND}" "-E" "copy" "${SOURCE_DIR}/builders/xml2/FindXML2.cmake" "${INSTALL_PREFIX}/share/cmake/Modules/FindXML2.cmake")
