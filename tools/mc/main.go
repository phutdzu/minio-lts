// Copyright (c) 2015-2026 MinIO, Inc.
//
// This file is part of MinIO Object Storage stack
//
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU Affero General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// This program is distributed in the hope that it will be useful
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU Affero General Public License for more details.
//
// You should have received a copy of the GNU Affero General Public License
// along with this program.  If not, see <http://www.gnu.org/licenses/>.

// Command mc is the MinIO client, built from the vendored github.com/minio/mc
// sources so that the Helm chart's post-install job has a client to use.
package main

import (
	"os"

	mc "github.com/minio/mc/cmd"
)

func main() {
	if err := mc.Main(os.Args); err != nil {
		os.Exit(1)
	}
}
